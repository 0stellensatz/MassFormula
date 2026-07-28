#!/usr/bin/env python3
"""Structural checks for the Lake project this script sits in.

Copied into every project as `<Project>/__check__.py`, it checks that project and
nothing else, so it can be wired into a hook or a CI step per project:

    python3 __check__.py        # from the project directory

Three checks, all textual (no build, no Lean required):

1.  Root imports --- the root module `<Project>/<Project>.lean` must directly
    import every module of the project, so that a plain `lake build` cannot
    silently omit a file.  `Challenge.lean` and `CompareMathlib.lean` are
    excluded: they share `Development.lean`'s namespace, so the root module
    carries Development and the other two are built by name.  Importing either
    from the root module is an error in its own right.

2.  Comparator isolation --- the three comparator files of one unit carry one
    declaration list under one namespace, so no module may *reach* two of them,
    whether by direct import or along any chain of imports.  Lean catches only
    part of this: it rejects a duplicate `def` outright, even one whose two
    copies agree in every respect, but it accepts two `theorem`s whose types
    match syntactically and silently keeps one body.  A unit whose targets are
    all theorems therefore merges without an error or a warning, and which body
    survives is unspecified --- last import wins on Lean v4.28.0, first import
    wins on v4.32.1 --- so a `sorry`ed Challenge target can supersede a proved
    Development one and everything downstream of it becomes vacuous.

3.  Comparator --- inside one unit directory, `Challenge.lean`,
    `Development.lean` and `CompareMathlib.lean` must expose the same
    declarations, of the same kind, with the same attributes and signature, in
    the same order.  Docstrings are compared between Challenge and Development
    only (a CompareMathlib docstring is expected to name the Mathlib lemmas it
    uses).

A project that uses no comparator (a set of exercise files, a run of dated logs)
simply has no `Challenge.lean`, and only the first check applies.  Exit status is
0 when the project is clean, 1 otherwise.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent
NAME = PROJECT.name

DECL_KEYWORDS = (
    "theorem",
    "lemma",
    "def",
    "abbrev",
    "structure",
    "class",
    "instance",
    "inductive",
    "axiom",
    "opaque",
)

MODIFIERS = ("private", "protected", "noncomputable", "partial", "unsafe", "scoped", "local")

DECL_RE = re.compile(
    r"^(?:(?:" + "|".join(MODIFIERS) + r")\s+)*(?P<kind>" + "|".join(DECL_KEYWORDS) + r")\s+(?P<name>\S+)"
)

COMPARATOR_FILES = ("Development.lean", "CompareMathlib.lean")

# The three files of one unit, which carry one declaration list under one
# namespace.  No environment may hold two of them.
COMPARATOR_TRIO = ("Challenge.lean", "Development.lean", "CompareMathlib.lean")

# The two of the trio the root module leaves out: `Development.lean` is the one
# it carries, and these are built by name.
ROOT_EXCLUDED_FILES = ("Challenge.lean", "CompareMathlib.lean")


class Decl:
    """One top-level declaration, reduced to what the comparator compares.

    `signature` carries the declaration's attribute blocks ahead of the header,
    so that an `@[simp]` present on one side of the comparator and absent on the
    other is a difference like any other.
    """

    def __init__(self, kind: str, name: str, signature: str, docstring: str, line: int) -> None:
        self.kind = kind
        self.name = name
        self.signature = signature
        self.docstring = docstring
        self.line = line

    def key(self) -> tuple[str, str, str]:
        return (self.kind, self.name, self.signature)


def _truncate_at_body(text: str) -> str:
    """Return `text` truncated at the first `:=` sitting outside any bracket."""
    depth = 0
    i = 0
    while i < len(text):
        ch = text[i]
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        elif depth == 0 and text.startswith(":=", i):
            return text[:i]
        i += 1
    return text


def parse_declarations(path: Path) -> list[Decl]:
    """Extract the top-level declarations of a Lean file, in source order."""
    lines = path.read_text(encoding="utf-8").splitlines()
    decls: list[Decl] = []
    doc: list[str] = []
    attrs: list[str] = []
    in_doc = False
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if in_doc:
            doc.append(stripped.removesuffix("-/").strip())
            if stripped.endswith("-/"):
                in_doc = False
            i += 1
            continue

        if stripped.startswith("/--"):
            body = stripped[3:]
            if body.rstrip().endswith("-/"):
                doc = [body.rstrip()[:-2].strip()]
            else:
                doc = [body.strip()]
                in_doc = True
            i += 1
            continue

        if stripped.startswith("@["):
            # An attribute block, which may span lines and may be followed by
            # the declaration itself on the closing line.  Consume the block and
            # leave any remainder in place to be re-read as a declaration line.
            depth = 0
            while i < len(lines):
                current = lines[i]
                depth += current.count("[") - current.count("]")
                if depth > 0:
                    attrs.append(current.strip())
                    i += 1
                    continue
                close = current.rfind("]")
                attrs.append(current[: close + 1].strip())
                rest = current[close + 1 :].lstrip()
                lines[i] = rest
                if not rest:
                    i += 1
                break
            continue

        match = DECL_RE.match(line)
        if match:
            header = [line]
            j = i
            while j < len(lines):
                joined = "\n".join(header)
                if _truncate_at_body(joined) != joined:
                    break
                if lines[j].rstrip().endswith("where"):
                    break
                j += 1
                if j >= len(lines):
                    break
                nxt = lines[j]
                if not nxt.strip() or DECL_RE.match(nxt) or nxt.startswith(
                    ("/-", "--", "@[", "end ", "namespace ", "section ", "variable ", "open ")
                ):
                    j -= 1
                    break
                header.append(nxt)
            signature = _truncate_at_body("\n".join(header))
            signature = re.sub(r"\bwhere\s*$", "", signature.strip())
            if attrs:
                signature = " ".join(attrs) + " " + signature
            decls.append(
                Decl(
                    kind=match.group("kind"),
                    name=match.group("name"),
                    signature=" ".join(signature.split()),
                    docstring=" ".join(" ".join(doc).split()),
                    line=i + 1,
                )
            )
            doc = []
            attrs = []
            i = j + 1
            continue

        if stripped and not stripped.startswith(("/-", "--")):
            doc = []
            attrs = []
        i += 1
    return decls


def module_name(source: Path, lib_root: Path) -> str:
    parts = list(source.relative_to(lib_root).with_suffix("").parts)
    escaped = [p if not p[0].isdigit() else f"«{p}»" for p in parts]
    return ".".join([NAME] + escaped)


def project_modules() -> dict[str, Path]:
    """Map every module of the project to its source file, root module included."""
    lib_root = PROJECT / NAME
    modules = {}
    if lib_root.is_dir():
        modules = {
            module_name(source, lib_root): source
            for source in sorted(lib_root.rglob("*.lean"))
        }
    root_module = PROJECT / f"{NAME}.lean"
    if root_module.is_file():
        modules[NAME] = root_module
    return modules


def read_imports(source: Path) -> list[str]:
    """The modules a file imports directly, in source order."""
    return [
        line.split(None, 1)[1].strip()
        for line in source.read_text(encoding="utf-8").splitlines()
        if line.startswith("import ")
    ]


def check_root_imports(errors: list[str], modules: dict[str, Path]) -> set[str]:
    """Check the root module's import list; return the excluded modules it reaches for."""
    if not (PROJECT / NAME).is_dir():
        errors.append(f"the library directory {NAME}/ is missing")
        return set()
    if NAME not in modules:
        errors.append(f"the root module {NAME}.lean is missing")
        return set()

    imported = set(read_imports(modules[NAME]))
    expected = {
        name
        for name, source in modules.items()
        if name != NAME and source.name not in ROOT_EXCLUDED_FILES
    }
    excluded = {
        name for name, source in modules.items() if source.name in ROOT_EXCLUDED_FILES
    }

    for missing in sorted(expected - imported):
        errors.append(f"{NAME}.lean: does not import {missing}")
    for forbidden in sorted(imported & excluded):
        errors.append(
            f"{NAME}.lean: imports {forbidden}, which shares the comparator namespace"
            f" with its Development.lean and must be built by name instead"
        )
    for extra in sorted(
        name for name in imported - expected - excluded if name.startswith(f"{NAME}.")
    ):
        errors.append(f"{NAME}.lean: imports {extra}, which has no source file")

    return imported & excluded


def check_comparator_isolation(
    errors: list[str], modules: dict[str, Path], reported_at_root: set[str]
) -> None:
    """No module may reach two comparator files of one unit.

    Reachability, not the direct import, is what decides: a module that imports
    `Defs.lean` holds whatever `Defs.lean` imported in turn, and the merge is
    just as silent.  A violation is reported against the module where it first
    appears --- the one whose own import list brings the second file into reach
    --- rather than against every module downstream of it.  `reported_at_root`
    carries what the root-import check has already said, so a root module that
    imports one of the two excluded files is faulted once, not twice.
    """
    units: dict[Path, set[str]] = {}
    for name, source in modules.items():
        if source.name in COMPARATOR_TRIO:
            units.setdefault(source.parent, set()).add(name)
    units = {unit: members for unit, members in units.items() if len(members) > 1}
    if not units:
        return

    cache: dict[str, frozenset[str]] = {}

    def reachable(name: str, pending: frozenset[str] = frozenset()) -> frozenset[str]:
        """The modules of this project `name` puts in one environment, itself included."""
        if name in cache:
            return cache[name]
        if name in pending:  # an import cycle, which the build rejects anyway
            return frozenset()
        seen = {name}
        for imported in read_imports(modules[name]):
            if imported in modules:
                seen |= reachable(imported, pending | {name})
        cache[name] = frozenset(seen)
        return cache[name]

    for name in sorted(modules):
        direct = [i for i in read_imports(modules[name]) if i in modules]
        for unit, members in sorted(units.items()):
            held = reachable(name) & members
            if len(held) < 2:
                continue
            if name == NAME and members & reported_at_root:
                continue  # the root-import check has already faulted this one
            if any(len(reachable(i) & members) > 1 for i in direct):
                continue  # inherited whole from an import, and reported there
            errors.append(
                f"{name}: reaches {' and '.join(sorted(held))}, two comparator files"
                f" of {unit.relative_to(PROJECT)} that share one namespace"
            )


def check_comparator(errors: list[str], warnings: list[str]) -> None:
    lib_root = PROJECT / NAME
    if not lib_root.is_dir():
        return

    for challenge in sorted(lib_root.rglob("Challenge.lean")):
        unit = challenge.parent
        rel = unit.relative_to(PROJECT)
        base = parse_declarations(challenge)
        if not (unit / "Development.lean").is_file():
            errors.append(f"{rel}: Challenge.lean has no Development.lean")
        for name in COMPARATOR_FILES:
            other = unit / name
            if other.is_file():
                compare(rel, base, parse_declarations(other), name, errors, warnings)


def compare(
    rel: Path,
    base: list[Decl],
    other: list[Decl],
    other_name: str,
    errors: list[str],
    warnings: list[str],
) -> None:
    if [d.key() for d in base] != [d.key() for d in other]:
        base_names = [d.name for d in base]
        other_names = [d.name for d in other]
        for name in base_names:
            if name not in other_names:
                errors.append(f"{rel}/{other_name}: missing declaration `{name}` (in Challenge.lean)")
        for name in other_names:
            if name not in base_names:
                errors.append(f"{rel}/{other_name}: extra declaration `{name}` (not in Challenge.lean)")
        if base_names == other_names:
            for b, o in zip(base, other):
                if b.key() != o.key():
                    errors.append(
                        f"{rel}/{other_name}:{o.line}: `{o.name}` differs from Challenge.lean:{b.line}\n"
                        f"    Challenge:   {b.signature}\n"
                        f"    {other_name[:-5]}: {o.signature}"
                    )
        elif sorted(base_names) == sorted(other_names):
            errors.append(f"{rel}/{other_name}: declarations are in a different order from Challenge.lean")

    if other_name == "Development.lean":
        by_name = {d.name: d for d in other}
        for b in base:
            o = by_name.get(b.name)
            if o is not None and b.docstring != o.docstring:
                warnings.append(f"{rel}/{other_name}:{o.line}: docstring of `{o.name}` differs from Challenge.lean")


def main() -> int:
    if not (PROJECT / "lakefile.toml").is_file():
        print(f"error: {PROJECT} is not a Lake project (no lakefile.toml)", file=sys.stderr)
        return 1

    errors: list[str] = []
    warnings: list[str] = []
    modules = project_modules()
    reported_at_root = check_root_imports(errors, modules)
    check_comparator_isolation(errors, modules, reported_at_root)
    check_comparator(errors, warnings)

    for warning in warnings:
        print(f"warning: {warning}")
    for error in errors:
        print(f"error: {error}")
    if errors:
        print(f"\n{len(errors)} error(s) in {NAME}")
        return 1
    print(f"ok: {NAME}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
