# Editing conventions for (Markdown-styled) comments in Lean source files

How the prose *inside* a comment is written: line breaking, how mathematics is set, Markdown usage, emphasis. What each file and each declaration must *carry* as documentation—the comment forms and their delimiter layout, the module docstring skeleton, which declarations need a docstring, and how a work is cited—is a separate matter, governed by `./rules-documentation.md`.

**This project is written as personal notes, not aimed at upstreaming**, so the template's closing *When the target is Mathlib* section—the copyright header, cite keys resolving against `docs/references.bib`, a mandatory `## Tags`—is not copied here and none of it is in force. Everything below applies as written. (Restore that section from `templates/lean4/LeanTemplate/__docs__/rules-comments.md`, repo-root-relative, if the project ever turns upstream.)

## Hard wrap at 100 columns

Every line of a comment is hard-wrapped to at most 100 columns, breaking mid-sentence wherever the wrap falls. Comment prose is broken by *width*—neither per sentence nor per paragraph. (This is a rule about Lean comments only; the parent repository's per-paragraph Markdown convention still governs `.md` files.)

- `gfmt -w100` does the mechanical work, but **read its output before keeping it.** It reflows fenced code blocks, inline code spans, and `$ ... $` math as though they were prose, so a displayed proof state or a Lean expression can come back broken. Repair those by hand.
- **Never break inside a fenced code block, an inline code span, or a formula.** A line that cannot fit within 100 columns without such a break stays over-long: the content is Lean, and rewrapping it changes what it says.
- Nothing suppresses the check any more. The file-level `set_option` block is empty (`./rules-formalization-project.md`), so `linter.style.longLine` fires on a line that is genuinely too long, and that warning is the signal to rewrap.
- A continuation line of a Markdown construct—the second line of a bullet, of a numbered item, or of a `## References` entry—is indented **two spaces**, as Markdown requires for the continuation to belong to the item.

## Mathematics is carried by Lean, not by LaTeX

A comment states its mathematics in Lean—inside inline code spans and fenced blocks—and reaches for LaTeX math only when nothing else will do. Two reasons, both practical:

- **`$ ... $` is unreadable exactly where the comment is read.** `doc-gen` renders it through MathJax, but VS Code previews no math, so in the editor the formula stays raw source.
- **`$A$` and `` `A` `` are different things, and letting one stand for the other invites drift.** A code span is a claim about the source file; math italic is a claim about the paper. Once `$A$` is accepted as "the Lean `A`", nothing keeps the two in step when the declaration is renamed or its statement changes.

The code-span rule this rests on is unchanged: **what sits inside `` `...` `` must be meaningful as Lean**—an identifier that is (or would be) declared in the file, a syntax fragment carrying real data, a tactic, a theorem or file name, or a genuine Lean expression. What changes is the remedy when a formula is *not* Lean. Work down this ladder and stop at the first rung that works.

1. **A Unicode symbol meaningful in both mathematics and Lean—put the whole expression in a code span.** Lean's notation already covers most of what a statement needs: `` `n - 1 ≤ d L` ``, `` `c L = 0 ↔ ¬ ringChar 𝓀[K] ∣ n` ``, `` `1 / (q K : ℝ≥0∞) ^ c L.1` ``. Write the literal glyph—`ℝ`, `ℕ`, `→`, `←`, `↦`, `⊢`, `≤`, `∀`, `↔`, `⁻¹`—never the LaTeX command. A paper symbol that *has* a Lean name is named by it rather than reproduced: $\Sigma_n$ is `` `sigma K n` ``, $A_L$ is `` `integers L` ``, $\mathfrak{d}_{L / K}$ is `` `discIdeal L` ``.
2. **A symbol that says exactly what is meant in mathematics but means nothing (or something else) in Lean—keep the Lean parts in spans and leave the symbol outside them.** The extension "L over K" is written `` `L` `` / `` `K` ``, not `` `L / K` ``: `L` and `K` are genuine Lean types, but `/` is division in Lean and does not mean "extension of". The point is that the backticks stay honest—they wrap only what really is code, and the connective between them is prose.
3. **Not expressible in Unicode—say it in English, naming the Lean pieces in spans.** This is the normal outcome for a statement with subscripts, a big operator, or a quantified index, and it reads better than a formula anyway:

	```lean
	/-- The sum of `1 / (q K : ℝ≥0∞) ^ c L.1` over all `L` in `sigma K n` equals `n`. -/
	```

4. **Nothing above works—`$ ... $` (or `$$ ... $$`) as a fallback**, not as a default. Reach for it when the content is genuinely a displayed formula that neither Lean notation nor English can carry.

When rung 4 is used, the LaTeX inside it **inherits the parent repository's global editing conventions**, not a Lean-specific set:

- Symbol preferences follow the repository-root `__docs__/rules-math-symbols.md`—`\smallsetminus` over `\setminus`, `\subseteq` for inclusion (`\subset` reserved for strict), `\mathfrak{m}` / `\mathfrak{p}`, `\cong` over `\simeq`, `\emptyset`, and the rest.
- In-math spacing and layout follow the repository-root `__docs__/rules-latex.md`—function application is spaced before its argument (`v_L (\mathfrak{d})`, not `v_L(\mathfrak{d})`), and binary operators and relations are spaced on both sides (`L / K`, not `L/K`).
- **No preamble, so no template macros.** A comment has no preamble, so the repo's custom macros (the set-symbol shorthands `\ZZ`, `\QQ`, …, the `\Set{...}{...}` builder, `\powerseries`, and friends) are undefined. Use the plain LaTeX each stands for—`\mathbb{Z}`, not `\ZZ`; a written-out `\{ ... \mid ... \}`, not `\Set`—while keeping the macro-independent symbol *preferences* above.
- **Prose-level `.tex` conventions are overridden** (see *Markdown conventions* below): straight ASCII quotes rather than `` ``...'' ``, and the literal Unicode em dash `—` rather than `---` / `--`.

## Markdown conventions inside comment blocks

- **Inline code in backticks** for every Lean identifier / declaration name, tactic, syntax fragment, and file name.
- **Fenced code blocks** with triple backticks—used for displayed proof states, code snippets, and examples.
- **Bulleted lists** with `-` followed by a space.
- **Regular ASCII double quotes** `"..."` for quotes in prose. Do **not** use LaTeX-style `` ``...'' ``—that convention belongs in `.tex` sources, not in Lean comment blocks.
- **Em dash `—`** (the literal Unicode glyph, not the LaTeX `---` / `--`) for parenthetical asides.

## Emphasis, headers, and links

- **Italics with single asterisks** for a term being defined or emphasized in prose: `*proof state*`, `*goal*`, `*commutative*`.
- **Bold with double asterisks**, used sparingly: a named theorem or a major concept on first introduction (`**the mean value theorem**`), or in-sentence emphasis (`**nothing**`). Bold is *not* used to announce the source item a declaration transcribes—no `**Theorem 1** (p.5): …` opener—because that item is cited at the end of the docstring instead; see *Citing other works* in `./rules-documentation.md`.
- **Headers** follow the module docstring skeleton of `./rules-documentation.md`: `#` for the file title, `##` for its structural subsections, `###` for a subtitle inside a sectioning comment below the module header.
- **Markdown links** of the form `[text](url)`, allowing italics to nest inside the link text—`[*Loogle*](https://loogle.lean-lang.org/)`.
