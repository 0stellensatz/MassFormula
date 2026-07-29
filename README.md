# MassFormula

A Lean 4 formalization of the «mass formula» for the totally ramified extensions of a given degree of a local field, after J-P. Serre, *Une «formule de masse» pour les extensions totalement ramifiées de degré donné d'un corps local*, C. R. Acad. Sci. Paris **286** (1978), Série A, 1031–1036.

Both mass formulas of the paper are formalized and proved, together with the finiteness dichotomy and the convergence and orbit-counting remarks that accompany them. **`MassFormula/Development.lean` contains no `sorry`,** and neither does any file it imports.

The project is bound to the theorem, not to the paper: it does not follow Serre's exposition step by step, and where another treatment gives a more direct route to a lemma, that route is taken.

## How to read `sorry` in this repository

`MassFormula/Challenge.lean` proves all seven of its declarations by `sorry`. **This is by design and permanent**, so grepping for `sorry` across the repository is misleading unless you know which file you are looking at. The project is built around a *comparator pair*:

- **`Challenge.lean` is the frozen specification.** One declaration per numbered claim of the paper, ordered so that reading the file top to bottom reads like the paper itself, each proved by `sorry`. It is the file that does *not* change when a proof is found, and its `sorry`s mark statements of intent rather than gaps in an argument.
- **`Development.lean` restates exactly those declarations and discharges them**, delegating to the auxiliary files beside it. This is where the mathematics lives, and it is `sorry`-free.

The point of the split is that a target cannot be quietly weakened to fit a proof that happened to work: the statement is committed to before the proof exists, and any later change to it has to be made in `Challenge.lean` first and propagated. A structural checker enforces that the two files stay declaration-for-declaration identical:

```bash
python3 __check__.py
```

Because the two declare the same names in the same namespace, they cannot enter one environment. `lake build` builds `Development`; `Challenge` is built by name.

## Layout

Everything sits in one unit, directly in `MassFormula/`. Besides the comparator pair and the definitional layer `Defs.lean`, each auxiliary file carries one result:

| File | Result |
| --- | --- |
| `First.lean` | Theorem 1, the first mass formula |
| `Second.lean` | Theorem 2, the second mass formula |
| `Discriminant.lean` | the bound `n - 1 ≤ d L` on the discriminant exponent |
| `Tame.lean` | tameness as the vanishing of `c` |
| `Finiteness.lean` | the finiteness dichotomy of Remark 1° |
| `Convergence.lean` | the convergence claim of Remark 1° |
| `Orbit.lean` | the orbit count of Remark 3° |
| `EisensteinMonogenic.lean` | Eisenstein monogenicity of the ring of integers |
| `RootLifting.lean` | quantitative Newton–Hensel root lifting |
| `HaarScaling.lean` | the linear Haar scaling law |
| `UniformizerParam.lean` | the uniformizer parametrization |

`Defs.lean` is the production copy of the definitional layer, which the auxiliary files build on. `Challenge.lean` imports Mathlib and nothing else and carries its own clones of the definitions its targets mention, so the specification stands on its own and depends on none of the work; `Development.lean` bridges between the two.

## Building

Mathlib is pinned in `lake-manifest.json`, and `elan` will fetch the toolchain named in `lean-toolchain`. From this directory:

```bash
lake exe cache get   # once, before the first build—otherwise Mathlib compiles from source
lake build           # the development, and everything it imports
lake build MassFormula.Challenge
python3 __check__.py
```

## Provenance

This project is extracted from a private notes repository and keeps that repository's conventions, in its own copies under `__docs__/`. A few paths in the documentation refer to that repository and are not part of this one: `blurbs/trans/Serre1978.en.tex` is a working English translation of the paper, `notes/math/theme/Serre1978.tex` the reading note behind the formalization, and `bib/__main__.bib` the bibliography that cite keys such as `[Serre1978]` resolve against. They are left in place because they record where a statement came from, which is worth more than a path that resolves.

The paper itself is under copyright and is not reproduced here; the docstrings cite it by theorem, remark, and page. Page references `p.N` follow the translation's pagination, so the original journal page is `1030 + N`.

## License

Apache-2.0. See `LICENSE`.
