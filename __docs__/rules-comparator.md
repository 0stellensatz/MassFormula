# The Challenge / Development comparator pair

Every formalization project freezes the results it is chasing in a *comparator* file and proves them in a parallel file carrying the same declaration list. The convention follows the agent workflow of the `rigid` project (https://github.com/dagurtomas/rigid/blob/main/AGENTS.md), including its rule that the frozen file stands alone against Mathlib.

The point of the pair is that the *specification* and the *proof* cannot drift apart silently: a statement may only change by changing both files in the same commit, so no proof is ever quietly weakened to fit a proof that was easier to find.

## The three files

A unit (a project root, a chapter directory `CNN/`, a section directory `SNN/`—whichever the project's `CLAUDE.md` fixes) carries:

- **`Challenge.lean` — the frozen specification.** The definitions its targets are stated over, cloned into the comparator namespace, then one declaration per target, each proved by `sorry`. It imports `Mathlib` and nothing else.
- **`Development.lean` — the same declarations, solved.** Exactly the same list, importing the project's production modules and replacing each target's body with a proof drawn from them. The cloned definitions keep their bodies unchanged—a definition has nothing to solve. Bodies still unproved stay `sorry`.
- **`CompareMathlib.lean` — the optional third file.** Same list again, proved *directly off the Mathlib API* rather than by the source's own argument—the shortest idiomatic route, ideally a one-liner naming the exact Mathlib lemma. Like `Challenge.lean` it imports only Mathlib. It exists for projects whose material Mathlib already covers, where reading the two proofs side by side is the point. It shares the comparator namespace, so it too stays out of the root module and is built by name. Whether a project keeps one is recorded in its `CLAUDE.md`.

Production code—the real proofs, in the auxiliary files—lives outside the three, under the project's own namespace, and is governed by `./rules-formalization-project.md`.

## A comparator file imports only Mathlib

**`Challenge.lean` imports `Mathlib` (or `Mathlib.*`) and nothing else**—not the unit's `Defs.lean`, not an auxiliary file, not another unit's `Challenge.lean`. `CompareMathlib.lean` is bound by the same rule: it carries the same declaration list, so it would have to hold the same definitions in any case, and reaching Mathlib by the shortest route is its whole purpose. `Development.lean` is the one file of the three that imports the project, since delegating to the production modules is what it is for.

A comparator file therefore **clones, into the comparator namespace, every definition its targets are stated over**, ahead of the targets themselves. The clones are declarations like any other: they stand in all three files, in the same order, with the same signatures—and, a definition having nothing to solve, with the same bodies. They are independent copies of the production API and never references to it. `Defs.lean` and the auxiliary files hold the originals under `<Project>`; each comparator file holds its own copies under `<Project>Challenge`; the two towers never meet.

A definition that cannot elaborate without a proof brings that proof with it: the well-formedness lemmas `Defs.lean` carries for the sake of its definitions—the nonemptiness a `max'` needs, the range membership a `choose` needs—are part of the definitional layer and are cloned alongside what they serve. A `Challenge.lean` therefore does hold some real proofs. What it must never hold is a proof of a *target*, and the distinction is exactly the one `Defs.lean` was already held to.

**The benchmark is then `Challenge.lean` alone**: one file, self-contained against Mathlib, stating what is wanted and proving none of it. Nothing beyond Mathlib has to be trusted to read it, and no companion file can quietly weaken it. The older architecture—`Challenge.lean` sharing the unit's `Defs.lean`—bought the same guarantee only by imposing two standing obligations (import only Mathlib, prove no target) on a file that was not itself a specification, so a single slip in `Defs.lean` silently voided the benchmark.

The price is paid twice over, and it is real. The definitional layer is now maintained in two places, three where a `CompareMathlib.lean` exists, with nothing but `Defs.lean` and the clones agreeing by hand; `__check__.py` compares the clones' *signatures* across the comparator files like any other declaration, but neither it nor Lean relates a clone to the `Defs.lean` original at all. And every Development body must cross from the clone to that original, which is the next section.

### Bridging a clone to the production API

A cloned `def` or `abbrev` is definitionally equal to its original—same body, different namespace—so the two unfold to each other and a Development body delegating to a production lemma typechecks as it stands.

A cloned `structure`, `inductive`, or `class` is a **different type**, and no unfolding relates it to its original. This is the case that used to force the shared `Defs.lean`, and the way through it is to convert at the boundary, inside the body of each target that needs it: take the comparator-namespace term apart with `obtain` (or `have`), rebuild the production term with the anonymous constructor `⟨...⟩`, apply the production result, and reassemble the comparator-namespace conclusion the same way.

```lean
theorem foo (x : Widget) (hx : IsGood x) : IsBetter x := by
  obtain ⟨mono, bound⟩ := hx
  obtain ⟨h₁, h₂⟩ := <Project>.foo ⟨x.toFun, x.mono'⟩ ⟨mono, bound⟩
  exact ⟨h₁, h₂⟩
```

The rebuilt term is accepted because a field of the clone reduces to the corresponding field of the original: `(⟨x.toFun, x.mono'⟩ : <Project>.Widget)` and `x` reach their arguments through their respective `FunLike` instances, and both unfold to `x.toFun`, so a hypothesis about one *is* a hypothesis about the other. This recurses through nested clones—a clone whose field mentions a second clone reduces along with it—and bottoms out because everything is ultimately built from Mathlib types, which the two towers share. A field that could not be traced back to Mathlib this way would be a definition the clone had no honest copy of, and the target mentioning it is the thing to restate.

**No helper declaration may be added to `Development.lean` to shorten this.** The lists must match, so the bridge lives in the body of the target that needs it, however often that repeats. A bridge worth naming is named on the production side, in an auxiliary file—the body still has to cross the boundary itself.

The conversion is expected to carry most targets, not all. Where it genuinely cannot be written, the target stays `sorry` in `Development.lean` with a comment naming the obstruction, and it is the *statement* that gets revisited: restate the target in Mathlib's vocabulary so nothing has to be transported, and propagate the edit to every comparator file of the unit. Importing `Defs.lean` back into `Challenge.lean` is not among the options.

Later units build on earlier ones in the Development tower only, by importing the earlier `Development.lean`. `Challenge.lean` and `CompareMathlib.lean` reach no earlier unit, so a later unit's comparator re-clones whatever earlier definitions its own targets mention.

## Namespaces

- Production declarations, and everything in `Defs.lean`, live in the project's root namespace `<Project>`.
- **All three comparator files use the one comparator namespace `<Project>Challenge`**—`Challenge.lean`, `Development.lean`, and `CompareMathlib.lean` alike, clones and targets together. Its being distinct from `<Project>` is what lets Development delegate to a production declaration of the same short name without a clash; its being *shared* across the three is what makes them literal alternatives, one declaration list under one set of names, and is why no two of them may meet in one environment (see below).
- Dot notation works inside the comparator namespace, because the clone a target's hypothesis is typed by lives there too: `IsJumpSetWithin.isJumpPairWithin` applies to a term of type `<Project>Challenge.IsJumpSetWithin`. The production restatement in the auxiliary file provides it independently, over `<Project>.IsJumpSetWithin`.
- `Development.lean` needs `open <Project>` to name the production declarations it delegates to, and it is the only file where a short name has both a clone and an original in scope. **The clone wins**—a declaration of the enclosing namespace takes precedence over one reached by `open`, with no ambiguity error (checked on Lean v4.28.0). That is the right default, since it is the clone the statements must be about; but it means a delegation that *wants* the original gets the clone silently. Write the production one `<Project>.foo` in full at the call site, every time.

## The declaration lists must match exactly

Across the files of one unit, preserve **names, kinds, binders, types, attributes, and order**, together with the docstrings. The only differences permitted are the `import` block and the bodies of the *targets*.

- **A cloned definition's body must match too.** A definition has nothing to solve, so a clone whose body differs across two comparator files means the two files specify different objects—precisely the silent drift the pair exists to prevent. `__check__.py` compares signatures and not bodies, so this one is on the editor: copy the clone block between the files verbatim rather than retyping it.
- The clones come first, in dependency order, and the targets after them, in the order of the source. A clone no target mentions does not belong in the comparator files at all.
- **A data-valued *target* is not a clone.** A construction the source itself asks for—a correspondence it builds, a definition whose well-formedness is one of its numbered claims—is declared among the targets, has no production original to be a copy of, and may legitimately differ between `Development.lean` and `CompareMathlib.lean`. Which of the two a `def` is decides whether its body may vary, so keep the clone block and the target block visibly separate.
- Never delete an implemented declaration from `Development.lean` to make something typecheck.
- When the specification changes, make the same declaration-level edit in every file of the unit **in the same commit**. The safe order is: edit `Challenge.lean` first, copy the changed declaration verbatim into the others, then restore each one's body.
- When closing a target, edit **only its body** in `Development.lean`. The Challenge declaration and its `sorry` body stay untouched—`Challenge.lean` is a specification, not a progress tracker.
- A declaration that is genuinely private scaffolding (a helper the API does not expose) does not belong in the comparator files at all; it belongs in an auxiliary file. This includes any bridge a Development body wants: the lists must match, so a comparator file gains no helper of its own.

## Never in one environment

The three comparator files declare the same names in the same namespace, so **no module may reach more than one of them**—not by importing two directly, and not by importing one file that in turn imports another. The root all-import module imports `Development.lean` only; `Challenge.lean` and `CompareMathlib.lean` are built by name. `__check__.py` checks the root module's own import list for the two by name, and separately walks the whole import graph for any module that ends up holding two files of one unit.

**Lean catches only part of the mistake, and not the part that matters.** A duplicate `def` is rejected outright on import, even when its two copies agree in every respect down to the body; so is a duplicate `theorem` whose two types differ, including types that are definitionally equal but not syntactically so. What passes is two `theorem`s whose types match *syntactically*: those are accepted and merged, their bodies being irrelevant by proof irrelevance. The comparator's whole discipline is that the declaration lists match verbatim, so an accidental co-import lands in precisely the tolerated case—no error, no warning, one of the two bodies silently dropped. Which one survives is unspecified and has changed between releases—last-import-wins on Lean v4.28.0, first-import-wins on v4.32.1—so a `sorry`ed Challenge target can quietly supersede a proved Development one, and everything downstream of it becomes vacuous without a diagnostic.

A unit is therefore exposed exactly to the extent that its declaration list is theorems: one data-valued declaration in the list is enough for the build to fault a co-import, and a unit of theorems alone has nothing but `__check__.py` standing between it and a silent merge. Cloning the definitions into the list has narrowed the gap—a unit needing any definition of its own now carries a `def` or a `structure`, and its co-imports fault outright—but a unit whose targets are stated in Mathlib's vocabulary alone still clones nothing and remains fully exposed. Do not read a clean build as evidence either way. `#print axioms <target>` is what exposes the merge after the fact; keeping the files out of each other's reach is what prevents it.

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

It performs four structural checks:

1. The root all-import module directly imports every module of the project except the two built by name, and imports neither of those—so no file can be silently dropped from the build.
2. No module of the project reaches two comparator files of one unit, by direct import or along any chain of imports—so no collision can be silently merged into the build. A violation is reported against the module whose own import list first brings the second file into reach, not against everything downstream of it.
3. `Challenge.lean` and `CompareMathlib.lean` import nothing but `Mathlib`—so a Challenge stands alone as the benchmark it is meant to be.
4. The comparator files of each unit expose the same declarations, of the same kind, with the same attributes and signature, in the same order.

It is a textual check on the sources, so it is fast and needs no build; it does not verify *elaborated* types, which only a build does—a `variable` silently dropped from one side is caught by the build, not by the script. Nor does it compare declaration *bodies*, so a cloned definition that drifts between two comparator files passes check 4; copying the clone block verbatim is what prevents that. Since the two excluded files are outside the default target, each needs its own build:

```bash
lake build
lake build <Project>.<Unit>.Challenge
lake build <Project>.<Unit>.CompareMathlib
```

`sorry` warnings from the comparator files are expected. Production modules should build without them.
