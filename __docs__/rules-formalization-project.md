# Architecture for source-formalization projects

These rules govern any Lake project that formalizes a piece of mathematical literature unit by unit—a *unit* being the project root itself, a book chapter (`CNN/`), or a paper section (`SNN/`), as fixed by the project's own `CLAUDE.md`. That `CLAUDE.md` also fixes the project's root namespace, its source of truth (the reading note under `notes/math/theme/` and/or the cached PDF), whether it keeps a `CompareMathlib.lean`, and any statement policy layered on top of these rules.

Two companion documents carry the parts not repeated here: `./rules-comparator.md` (the Challenge / Development pair—the specification-versus-proof split that these rules assume throughout) and `./rules-documentation.md` (module and declaration docstrings, and citations).

## The project is a Lake package

Each project under `notes/code-lean4/` is a self-contained Lake package with its own `lakefile.toml`, `lean-toolchain`, `lake-manifest.json`, and (gitignored, machine-local) `.lake/`—so it can be worked on, built, and if ever wanted published, on its own. The sources sit in the library directory named after the project:

```
<Project>/
├── lakefile.toml   lean-toolchain   lake-manifest.json   .gitignore
├── README.md   CLAUDE.md   AGENTS.md → CLAUDE.md
├── __docs__/            the project's own copies of the rules it follows
├── __check__.py         the project's own copy of the structural checker
├── <Project>.lean       the root all-import module
└── <Project>/           the library source tree
```

The `__docs__/` copies and `__check__.py` come from `templates/lean4/` (repo-root-relative) when the project is created, and are the project's own from then on: they are fine-tuned in place to fit it, and a project carries only the rules that apply to it.

Module names mirror file paths under the package root: `<Project>/<Unit>/Foo.lean` is the module `<Project>.<Unit>.Foo`.

**The root module `<Project>.lean` directly imports every module of the project**, so a plain `lake build` cannot silently omit a new file. Keep the import list sorted, and add to it whenever a module is added or renamed. The exceptions are `Challenge.lean` and `CompareMathlib.lean`, which declare the same names in the same namespace as `Development.lean` and so cannot enter the same environment; the root module imports Development, and the other two are built by name.

## Layout: one directory per unit

Each unit consists of:

- **`Challenge.lean` — the frozen statement of the unit's targets**, one declaration per numbered claim of the source, each proved by `sorry`, over its own clones of the definitions they mention. Reading it top to bottom should read like the source unit itself. It imports only Mathlib, and it is the file that does *not* change when a proof is found.
- **`Development.lean` — the same declarations, discharged** by delegating to the auxiliary files, each body bridging from the clone to the production original (`./rules-comparator.md`). This is the unit's public, source-facing face.
- **`Defs.lean` — the unit's production definitions:** structures, instances, notation, and `rfl`-level unfolding lemmas. The auxiliary files import it, and `Development.lean` through them; the comparator files clone what they need instead of reaching for it.
- **Auxiliary files `<Result>.lean`** — one per goal (or per tight cluster of goals), named in UpperCamelCase after the result proved, with the source tag recorded in the module docstring. This is where the actual multi-line proofs live.
- **`CompareMathlib.lean`** — optional; see `./rules-comparator.md`.

## Import discipline

Lean's import graph is acyclic, and the comparator sits at the top of the unit, so nothing in a unit may import its own `Development.lean`. The flow within a unit is fixed:

```
Defs.lean  ←  auxiliary files  ←  Development.lean

Mathlib  ←  Challenge.lean,  CompareMathlib.lean
```

- Auxiliary files import `Defs.lean` (and one another as needed), never `Development.lean`. This is why the production definitions sit in `Defs.lean` rather than only in `Development.lean`: the auxiliary files must be able to state their lemmas.
- **`Challenge.lean` and `CompareMathlib.lean` sit outside this graph entirely**—they import Mathlib alone and carry their own clones of the definitions their targets mention (`./rules-comparator.md`). `Defs.lean` and the clones are maintained in step by hand.
- When a definition in `Defs.lean` carries a proof obligation, prove the obligation in place when it is short; if it grows, split it into a prerequisite auxiliary file imported *by* `Defs.lean`. Never leave a `sorry` in `Defs.lean`.
- A definition whose proof obligation *is* one of the source's numbered claims lives in the comparator files only (declared after the claim it depends on), so the obligation stays a visible goal; it has no counterpart in `Defs.lean`, and auxiliary files must not reference it.
- Later units build on earlier ones by importing their `Development`: a unit's `Defs.lean` starts from `import <Project>.<PrevUnit>.Development`. A later unit's comparator files import nothing at all beyond Mathlib, so they re-clone whatever earlier definitions their own targets mention.

## Workflow

1. **Skeleton.** Write `Challenge.lean` from the source against Mathlib alone: the definitions its targets need, cloned into the comparator namespace, then every target as a `sorry`. Copy the clone block into `Defs.lean` under the project namespace, which is where the production tower will build on it. Copy `Challenge.lean` whole to `Development.lean` and adjust only its module docstring and imports. The unit must build at this stage (`warningAsError false` keeps `sorry` a warning, not an error).
2. **Fill.** Pick a `sorry` in `Development.lean`, create (or extend) the auxiliary file for it, and prove the result there over the `Defs.lean` definitions. An auxiliary file may carry `sorry`s while work on it is in progress.
3. **Discharge.** Once the auxiliary proof is `sorry`-free, add its `import` to `Development.lean` and replace the `sorry` with a body that bridges from the clones to the production API and delegates to it—for definitions that are `def`s, a one-liner; for cloned structures, the `obtain` / `⟨...⟩` conversion of `./rules-comparator.md`. **The statement never changes at this step, only its body**, and `Challenge.lean` is not touched at all.

If step 3 cannot be carried out without changing the statement, the statement was wrong: fix it in `Challenge.lean` first, propagate the identical edit to the other comparator files of the unit, and only then adjust the proof.

## Namespaces and naming

- Production declarations live in the project's root namespace; source-level objects get nested namespaces for dot notation. The comparator files share a namespace of their own (`./rules-comparator.md`).
- The comparator files own the public, source-facing names, in descriptive Mathlib style. **Every non-comparator file declares `namespace MassFormula` flat, with no per-file sub-namespace**—a deliberate departure from the template, whose sub-namespace exists only so a concluding lemma can restate its target without a name clash. That clash cannot arise here: the targets live in the comparator namespace `MassFormulaChallenge`, not in `MassFormula`, so a concluding lemma is free to carry the target's own name. Helpers not meant for use outside their file stay `private`, which Lean mangles per module and so never collides even under one namespace.
- Two consequences of the flat namespace. A cross-file reference is written bare (`exists_eisenstein_generator`, not `Discriminant.exists_eisenstein_generator`), so nothing but the `import` line records which file a lemma came from; and a file name no longer names a namespace, so renaming a file touches its `import` lines and nothing else. What keeps this safe is that **no declaration name is used twice across the non-comparator files**—check that before adding one, since Lean merges two matching theorems in silence.
- Docstrings on source-facing declarations cite the source's numbering and page, matching the reading note—see `./rules-documentation.md`.
- Modeling decisions (how a source object is encoded—e.g. `ℤ_{≥1}` as `ℕ+`) are recorded once, in the `## Implementation notes` of the `Challenge.lean` that introduces them, and stay consistent across units.
- When a declaration's natural name collides with the Mathlib lemma it mirrors, the Mathlib one is reachable as `_root_.<name>`; prefer a distinct descriptive name when the collision would confuse.

## File layout

Every `.lean` file starts with `import Mathlib`, then the project-local imports (each on its own line), then the module docstring:

```lean
import Mathlib
import <Project>.<Unit>.Defs

/-!
# <title>
...
-/
```

In `Challenge.lean` and `CompareMathlib.lean` the block stops at the first line: they take no project-local import at all.

**There is no file-level `set_option` block.** The suppressions this tree used to open every file with—`warningAsError false`, `linter.style.longLine false`, `linter.style.emptyLine false`—are gone, and the set is empty: nothing stands between a file and the Mathlib linter set that `lakefile.toml` enables. The long-line linter in particular is now a check the file is expected to pass, since comments are hard-wrapped at 100 columns (`./rules-comments.md`).

A `set_option` that changes *elaboration* rather than silencing a linter is a different matter and stays available—but only in the scoped form, attached to the one declaration that needs it and carrying a comment saying why:

```lean
set_option maxHeartbeats 1000000 in
-- The instance search for `IsDedekindDomain (integers L)` is the expensive step.
theorem foo : ... := ...
```

This is what Mathlib's own `linter.style.setOption` demands; an unscoped `set_option maxHeartbeats` at the top of a file is reported by it.

**Four unscoped sites in this project are a recorded exception.** `RootLifting.lean` and `UniformizerParam.lean` open with an unscoped `synthInstance.maxHeartbeats` / `maxHeartbeats` pair, and `First.lean` carries two more part-way down; between them they govern well over a hundred declarations whose elaboration is uniformly expensive. Scoping each one would add two lines per declaration and change nothing about what Lean does, so the unscoped form stays and `linter.style.setOption` goes on reporting it. The exemption covers those four existing sites only—a declaration added from here on takes the scoped form above.

## Building

All of these are run from the project directory (from elsewhere, wrap the change of directory in a subshell so it does not leak into later commands):

```bash
lake build                               # the whole project
lake build <Project>.<Unit>.Development  # one unit
lake build <Project>.<Unit>.Challenge    # the comparator, separately
lake build <Project>.<Unit>.CompareMathlib   # likewise, when the project keeps one
```

A fresh checkout of a project needs `lake exe cache get` **before** the first build—otherwise Lean compiles Mathlib from source, which takes hours. Alongside the build, run the project's own structural check (`./rules-comparator.md`):

```bash
python3 __check__.py
```

The toolchain and the remaining `lake` commands are documented in the project's own `README.md`, one directory up from this one.
