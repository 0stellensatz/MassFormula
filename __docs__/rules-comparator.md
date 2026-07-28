# The Challenge / Development comparator pair

Every formalization project freezes the results it is chasing in a *comparator* file and proves them in a parallel file carrying the same declaration list. The convention is adapted from the agent workflow of the `rigid` project (https://github.com/dagurtomas/rigid/blob/main/AGENTS.md); the deviation this tree's `Defs.lean` architecture forces is marked below.

The point of the pair is that the *specification* and the *proof* cannot drift apart silently: a statement may only change by changing both files in the same commit, so no proof is ever quietly weakened to fit a proof that was easier to find.

## The three files

A unit (a project root, a chapter directory `CNN/`, a section directory `SNN/`—whichever the project's `CLAUDE.md` fixes) carries:

- **`Challenge.lean` — the frozen specification.** One declaration per target, each proved by `sorry`. It never imports a module that proves a target.
- **`Development.lean` — the same declarations, solved.** Exactly the same list, importing the project's production modules and replacing each body with a term or proof drawn from them. Bodies still unproved stay `sorry`.
- **`CompareMathlib.lean` — the optional third file.** Same list again, proved *directly off the Mathlib API* rather than by the source's own argument—the shortest idiomatic route, ideally a one-liner naming the exact Mathlib lemma. It exists for projects whose material Mathlib already covers, where reading the two proofs side by side is the point. It shares the comparator namespace, so like `Challenge.lean` it stays out of the root module and is built by name. Whether a project keeps one is recorded in its `CLAUDE.md`.

Production code—the real proofs, in the auxiliary files—lives outside the three, under the project's own namespace, and is governed by `./rules-formalization-project.md`.

## `Defs.lean` is shared, and that is the whole import rule

**The definitional layer is *never* re-declared in a comparator file.** The unit's `Defs.lean` holds it, and all four consumers—`Challenge.lean`, `Development.lean`, `CompareMathlib.lean`, and the auxiliary files—import it. The comparator files declare **only the targets**, and reach the definitions with `open <Project>`.

Two obligations keep `Challenge.lean` honest, and they fall on `Defs.lean`:

- **`Defs.lean` imports only `Mathlib` (or `Mathlib.*`)**—never an auxiliary file, never a `Development`.
- **`Defs.lean` proves no target.** It carries definitions, instances, notation, `rfl`-level unfolding lemmas, and the short well-formedness facts a definition needs—nothing that appears in `Challenge.lean`, and never a `sorry`.

The benchmark a Challenge represents is therefore the *pair* (`Defs.lean`, `Challenge.lean`): still self-contained against Mathlib, still free of any proof of what it asks for.

The alternative—`Challenge.lean` importing only Mathlib and re-declaring the definitions, as in `rigid`—does not survive contact with this architecture. A `structure`, `inductive`, or `class` re-declared in the comparator namespace is a *different type*, so no production proof could ever discharge the corresponding Development body; and for the definitions that *could* be delegated, the same definition would have to be kept in step across three files by hand. One rule for every unit is worth more than a Challenge that stands alone as a single file.

Later units build on earlier ones *within their own tower*: a unit's `Challenge.lean` may import an earlier unit's `Challenge.lean`, its `Development.lean` the earlier `Development.lean`, and its `CompareMathlib.lean` the earlier `CompareMathlib.lean`—never across towers. The three towers are parallel and never meet.

## Namespaces

- Production declarations, and everything in `Defs.lean`, live in the project's root namespace `<Project>`.
- **All three comparator files use the one comparator namespace `<Project>Challenge`**—`Challenge.lean`, `Development.lean`, and `CompareMathlib.lean` alike. Its being distinct from `<Project>` is what lets Development delegate to a production declaration of the same short name without a clash; its being *shared* across the three is what makes them literal alternatives, one declaration list under one set of names, and is why no two of them may meet in one environment (see below).
- A target named for dot notation (`IsJumpSetWithin.isJumpPairWithin`) does not provide it inside the comparator namespace, since the hypothesis's type lives in `<Project>`. Keep the name for its descriptive value; dot notation comes back with the production restatement in the auxiliary file.

## The declaration lists must match exactly

Across the files of one unit, preserve **names, kinds, binders, types, attributes, and order**, together with the docstrings. The only differences permitted are the `import` block and the declaration bodies.

- Never delete an implemented declaration from `Development.lean` to make something typecheck.
- When the specification changes, make the same declaration-level edit in every file of the unit **in the same commit**. The safe order is: edit `Challenge.lean` first, copy the changed declaration verbatim into the others, then restore each one's body.
- When closing a target, edit **only its body** in `Development.lean`. The Challenge declaration and its `sorry` body stay untouched—`Challenge.lean` is a specification, not a progress tracker.
- A declaration that is genuinely private scaffolding (a helper the API does not expose) does not belong in the comparator files at all; it belongs in an auxiliary file.
- A definition whose well-formedness *is* one of the source's numbered claims is the exception that stays in the comparator files rather than in `Defs.lean`—its obligation fields are goals, so they belong with the goals.

## Never in one environment

The three comparator files declare the same names in the same namespace, so **no module may reach more than one of them**—not by importing two directly, and not by importing one file that in turn imports another. The root all-import module imports `Development.lean` only; `Challenge.lean` and `CompareMathlib.lean` are built by name. `__check__.py` checks the root module's own import list for the two by name, and separately walks the whole import graph for any module that ends up holding two files of one unit.

**Lean catches only part of the mistake, and not the part that matters.** A duplicate `def` is rejected outright on import, even when its two copies agree in every respect down to the body; so is a duplicate `theorem` whose two types differ, including types that are definitionally equal but not syntactically so. What passes is two `theorem`s whose types match *syntactically*: those are accepted and merged, their bodies being irrelevant by proof irrelevance. The comparator's whole discipline is that the declaration lists match verbatim, so an accidental co-import lands in precisely the tolerated case—no error, no warning, one of the two bodies silently dropped. Which one survives is unspecified and has changed between releases—last-import-wins on Lean v4.28.0, first-import-wins on v4.32.1—so a `sorry`ed Challenge target can quietly supersede a proved Development one, and everything downstream of it becomes vacuous without a diagnostic.

A unit is therefore exposed exactly to the extent that its declaration list is theorems: one data-valued declaration in the list is enough for the build to fault a co-import, and a unit of theorems alone has nothing but `__check__.py` standing between it and a silent merge. Do not read a clean build as evidence either way. `#print axioms <target>` is what exposes the merge after the fact; keeping the files out of each other's reach is what prevents it.

## Section variables

Keep an assumption that does not occur syntactically in a result explicit with `include ... in`. Lean includes a section `variable` in a declaration only when the declaration's statement or *body* mentions it, so a hypothesis used by a `sorry`-free Development body—but absent from the statement—would silently enter Development's elaborated type while missing from Challenge's, breaking the match in exactly the case that is hardest to notice.

```lean
variable (K : Type*) [Field K] [ValuativeRel K] [IsUniformAddGroup K]

include ‹IsUniformAddGroup K› in
theorem foo : ... := ...
```

(The `include`/`omit` commands were absent from early Lean 4 and reintroduced for section variables; they are current Lean 4 and are used throughout Mathlib.)

**`include ... in` is the only tool for this**, one occurrence per declaration that needs it. The alternative this tree used to reach for—`set_option linter.unusedSectionVars false` at the top of the file—is no longer available: the file-level `set_option` block is empty (`./rules-formalization-project.md`). It was in any case the weaker instrument, since it silences the warning without changing what Lean includes; the mismatch it was meant to guard against is fixed by `include`, not by the linter setting.

**In this project the resulting warnings are left standing, and that is deliberate.** The auxiliary tower carries `[IsUniformAddGroup K]` uniformly, because completeness is what makes `K` a genuine local field and so what makes every statement in the tower the intended one; a proof that happens not to need it is still a proof about those objects. Lean therefore reports the variable unused on dozens of declarations across the auxiliary files, and that output is expected rather than a to-do list. An `omit ... in` on each would buy a formally stronger statement at the price of an uneven hypothesis list across a tower whose comparator targets all carry the hypothesis—so read the warnings as noise and leave them. This is an exemption from answering the warning, not from the rule above: `include ... in` is still the tool wherever a declaration genuinely needs a variable Lean would otherwise drop.

## Checking

Each project carries its own copy of the checker, so a hook or a CI step can run it per project. From the project directory:

```bash
python3 __check__.py
```

It performs three structural checks:

1. The root all-import module directly imports every module of the project except the two built by name, and imports neither of those—so no file can be silently dropped from the build.
2. No module of the project reaches two comparator files of one unit, by direct import or along any chain of imports—so no collision can be silently merged into the build. A violation is reported against the module whose own import list first brings the second file into reach, not against everything downstream of it.
3. The comparator files of each unit expose the same declarations, of the same kind, with the same attributes and signature, in the same order.

It is a textual check on the sources, so it is fast and needs no build; it does not verify *elaborated* types, which only a build does—a `variable` silently dropped from one side is caught by the build, not by the script. Since the two excluded files are outside the default target, each needs its own build:

```bash
lake build
lake build <Project>.<Unit>.Challenge
lake build <Project>.<Unit>.CompareMathlib
```

`sorry` warnings from the comparator files are expected. Production modules should build without them.
