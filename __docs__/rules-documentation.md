# Documentation rules for Lean source files

What every file and every declaration must *carry* as documentation. (How the prose inside a comment is formatted—line breaking, how mathematics is set, Markdown usage—is a separate matter, governed by `./rules-comments.md`.)

These rules follow the Mathlib documentation guidelines (https://leanprover-community.github.io/contribute/doc.html), with the adaptations this repository forces—chiefly that citations resolve against `bib/__main__.bib` rather than Mathlib's `docs/references.bib`. Projects that follow the Mathlib guidelines here stay upstreamable; projects that do not still get the part that matters most for reading notes, which is *saying where a statement comes from*.

## The four comment forms

Each has one job, and the choice is not stylistic:

- `/-! ... -/` — **module docstrings** and sectioning comments. Documentation-generator visible.
- `/-- ... -/` — **declaration docstrings**. They attach to the following `def` / `theorem` / `lemma` / `structure` / `class` / `instance` and surface as editor hover text.
- `/- ... -/` — **technical comments**: TODOs, implementation notes, comments inside proofs. Not documentation.
- `--` — short or end-of-line comments.

A block of prose that documents the file must therefore be `/-! ... -/`, not `/- ... -/`.

**The delimiters are laid out differently for the two documentation forms**, and the difference is what distinguishes prose from a caption at a glance:

- **`/-- ... -/` hugs its text.** The docstring starts on the same line as `/--` and ends on the same line as `-/`, however many lines it runs to. A one-liner is `/-- Sentence -/`—spaced, never broken across three lines.

	```lean
	/-- `c L = 0` if and only if `n` is prime to `p`, in other words if and only if the extension
	`L` / `K` is tamely ramified. -/
	```

- **`/-! ... -/` puts its delimiters on their own lines** whenever it carries prose, which is what a module docstring always does.
- **A one-line sectioning comment is the exception, and is spaced like a docstring**: `/-! ## The first mass formula -/`, on a single line. Only when a sectioning comment grows past a heading into prose does it take the broken form.

## Module docstring

Every source file opens—after its `import` block, and there is no `set_option` block to follow it (`./rules-formalization-project.md`)—with a module docstring. Its skeleton, in this order:

- `# <title>` — mandatory first-level header, the file's title.
- A summary paragraph of what the file contains.
- `## Main definitions` — the principal `def`s introduced here (may be folded into the summary).
- `## Main statements` — the principal theorems (may be folded into the summary).
- `## Notation` — mandatory if the file introduces notation.
- `## Implementation notes` — design decisions: how a source object is encoded, type-class choices, junk-value conventions, `simp`-normal forms.
- `## References` — mandatory in any file transcribing a source; see *Citing other works*.
- `## Tags` — a comma-separated keyword list, optional outside Mathlib.

Sections that do not apply are omitted rather than left empty. In a source-formalization project the unit narrative and the modeling decisions that `./rules-formalization-project.md` requires are exactly the summary and the `## Implementation notes` of this skeleton—write them there, not in a bare `/- ... -/` block.

## Declaration docstrings

- **Every `def` and every major theorem must have a docstring.** Lemmas want one too whenever they carry mathematical content or are likely to be reused; a purely local `private` helper need not.
- The docstring conveys the **mathematical meaning**. It may lie slightly about the implementation—say what the object *is*, not how it is encoded—but it must not lie about the statement.
- A docstring that is a complete sentence ends with a period.
- A theorem with a **name of its own** may be bold on first introduction—`**the mean value theorem**`, `**Hensel's lemma**`. A *source item* is not: never open a docstring with a bold marker announcing it (`**Theorem 1.**`, `**Proposition 1.7** (p.5):`). Say what the declaration states, and cite the item at the end—see *Citing other works*.
- The docstring says what the statement **means**, in the vocabulary of `./rules-comments.md`: Lean in code spans, English where Lean will not carry it, LaTeX math only as a fallback.
- Refer to Lean declarations in backticks, and prefer the **fully-qualified** name (`Finset.card_pos`, not `card_pos`): the documentation generator turns a fully-qualified name into a link, and the reader can grep it either way.
- Prefer a `[text](url)` link for an external reference; when a bare URL must appear inside a doc comment, enclose it in angle brackets `<...>` so it stays clickable in the rendered docs. This is a **deliberate override** of the repository-wide rule against angle-bracket autolinks (`__docs__/rules-markdown.md`, repo-root-relative), taken under that rule's own *unless otherwise specified*: a doc comment is rendered by the editor and by `doc-gen`, where an unwrapped URL is not a link at all. Do not "correct" it back.

## Citing other works

**Every claim taken from the literature carries its source.** This is the rule that matters most here: a reading-note formalization whose statements do not say where they come from is unusable a month later.

- A reference is cited by the **cite key of the shared bibliography**—`bib/__main__.bib`, or `bib/__main__.ja.bib` for a Japanese-language work—enclosed in square brackets: `[Pagano2022]`, `[Serre1978]`, `[ja_Takagi1971]`. The bracketed-key form is Mathlib's citation syntax, so a file that is later upstreamed only needs its entries moved to `docs/references.bib`.
- Custom link text goes ahead of the key in its own brackets: `[Corps Locaux][Serre1968]`. A closing `]` inside the link text breaks the syntax, so do not write `[Euclid's *Elements* [Prop. 1]][heath1956a]`.
- **Never invent a key.** Cite only a key that exists in the bibliography; if the work is not there, add it first (the `/pdf-to-bib` skill mints the entry and routes it to the right database by the language of the work), then cite the key it produced.
- A pinpoint follows the key inside the brackets, using the repo-wide abbreviations of `__docs__/rules-english.md`: `[Serre1968, Chap. III, §3]`, `[AtiyahMacDonald1969, p.8]`, `[Pagano2022, Prop. 2.3]`.
- **A declaration transcribing a source item cites it at the end of its docstring, parenthesized**, in the custom-link-text form—author, year, and pinpoint as the text, the key as the target:

	```lean
	/-- The sum of `1 / (q K : ℝ≥0∞) ^ c L.1` over all `L` in `sigma K n` equals `n`
	([Serre 1978, Theorem 1][Serre1978]). -/
	```

	This replaces the older habit of opening the docstring with a bold marker. The content of the statement comes first and the provenance last, so the hover text reads as mathematics rather than as a catalog entry. An unnumbered claim taken from running text cites the page in the same slot—`([Serre 1978, p.5][Serre1978])`.
- The file's `## References` section lists every work cited in it, **spelled out in full** and not only by key—these projects are not built by `doc-gen`, so a bare key resolves to nothing for a reader outside this repository:

	```lean
	/-!
	## References

	* [Serre1978] J-P. Serre, *Une «formule de masse» pour les extensions totalement ramifiées de
	  degré donné d'un corps local*, C. R. Acad. Sci. Paris **286** (1978), Série A, 1031–1036.
	-/
	```

- A statement whose *source of truth* is a reading note of this repository rather than the paper itself says so, with the repo-root-relative path: `notes/math/theme/Pagano2022.tex`. The paper is what is cited; the note is what was read.
- **Mathlib is cited by declaration name**, never by bibliography key: name the lemma in backticks (`Ideal.exists_maximal`). This is what makes a `CompareMathlib.lean` body self-documenting.

## What documentation is *not* for

Do not record in a docstring what the code already says (the binder list, the `simp` set used), nor progress state ("proved on 2026-07-12", "TODO: finish"). Progress belongs in a `/- ... -/` technical comment, a `TODO.md`, or the issue tracking the unit.
