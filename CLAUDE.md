# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this directory.

## Project

A Lean 4 formalization of the «mass formula» for the totally ramified extensions of given degree of a local field. The main reference is Jean-Pierre Serre, *Une «formule de masse» pour les extensions totalement ramifiées de degré donné d'un corps local*, C. R. Acad. Sci. Paris 286 (1978), Série A, 1031–1036 (cite key `Serre1978`)—but the project is bound to the theorem, not to that paper: it need not follow Serre's exposition section by section, and other treatments may inform the proofs where they are more direct.

The paper is in French; the faithful English translation `blurbs/trans/Serre1978.en.tex` (repo-root-relative) is the working copy of the source, reproducing the original's theorem/lemma numbering, equation tags `(1)`–`(24)`, and footnotes. The reading note `notes/math/theme/Serre1978.tex` mirrors the translation line by line and records the note-writer's `\sorry` gaps and `\green` fill-ins—consult it for which arguments have already been worked out informally. Page references in docstrings are the journal's own, `p.1031`–`p.1036`. The translation and the note paginate from `1`, so their `% p.N` markers sit at journal page `1030 + N`—an aid for navigating them, never a form a citation may take.

## Architecture

This is a standalone Lake package. The project follows the shared source-formalization architecture in @./__docs__/rules-formalization-project.md and the comparator discipline in @./__docs__/rules-comparator.md—the import discipline, the skeleton → fill → discharge workflow, the naming and docstring rules, and the build commands. The project-specific parameters are:

- **The project is a single unit, rooted in the library directory itself**: `Challenge.lean`, `Development.lean`, `Defs.lean`, and the auxiliary files sit directly in `MassFormula/MassFormula/`, with no per-section `SNN/` subdirectories—so modules are `MassFormula.<File>` and the build target is `MassFormula.Development`.
- **The root namespace is `MassFormula`**—the theorem's name, not a cite key, per the project's detachment from the paper. The comparator files use `MassFormulaChallenge`; `Development.lean` reaches the production declarations with `open MassFormula`.
- **`MassFormula` is also the *only* namespace**: every non-comparator file declares it flat, rather than the template's per-file sub-namespace, so cross-file references are written bare and a file name carries no namespace. `__docs__/rules-formalization-project.md` records why this is safe here and what it costs.
- **`Defs.lean` is the production definitional layer**, imported by the auxiliary files and by `Development.lean`—never by `Challenge.lean`, which imports Mathlib alone and clones what its targets need (`__docs__/rules-comparator.md`). The clones are cheap to bridge here: every object of the layer (`q`, `integers`, `IsTotallyRamified`, `sigma`, `discIdeal`, `d`, `c`, `w`, `IsRepresentativeSet`) is a `def`, so a clone is definitionally equal to its original and a Development body delegates without conversion.
- **There is no `CompareMathlib.lean`.** The file exists to contrast the source's argument with the Mathlib API, and this project has no such contrast to draw—see the next point.
- **Mathlib is used without restriction.** Unlike `AtiyahMacDonald1969/`, this project has no preliminary boundary: any Mathlib lemma may enter any proof, and the shortest available route is the right one.
- **The completeness hypothesis `[IsUniformAddGroup K]` is carried uniformly across the tower**, because it is what makes `K` a genuine local field and so what makes the statements the intended ones—even where a proof turns out not to need it and Lean reports the variable unused. Both of the standing exemptions this produces (those warnings, and four unscoped `maxHeartbeats` sites) are recorded in `__docs__/rules-comparator.md` and `__docs__/rules-formalization-project.md`; read the reasoning there.

## Editing conventions for the comments

Follow the rules in @./__docs__/rules-comments.md for Markdown-styled comments across the files, and @./__docs__/rules-documentation.md for the module docstrings, the per-declaration docstrings, and the citations.

This project carries four rule documents in `__docs__/`—`rules-comments.md`, `rules-documentation.md`, `rules-formalization-project.md`, `rules-comparator.md`—and its own copy of the structural checker:

```bash
python3 __check__.py
```

They are this project's copies of `templates/lean4/` (repo-root-relative) and are fine-tuned here, not there. The template's closing *When the target is Mathlib* section of `rules-comments.md` is deliberately dropped from the copy: this is a personal formalization, not a Mathlib contribution.
