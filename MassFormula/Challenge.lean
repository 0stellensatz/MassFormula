import Mathlib
import MassFormula.Defs

/-!
# Statement of the result

The mass formula for the totally ramified extensions of given degree of a local field: Theorem 1,
over the set `sigma K n` of such extensions inside a fixed separable closure, and Theorem 2, its
reformulation over a set of representatives of the isomorphism classes, together with the
surrounding prose claims and remarks ([Serre 1978][Serre1978]).

This is the project's frozen specification: it declares one target per claim of the source, each
proved by `sorry`, over the shared definitional layer of `Defs.lean`—which imports only Mathlib and
proves none of these targets, so the pair (`Defs.lean`, `Challenge.lean`) is self-contained and
proof-free.
The same declarations, discharged, are in `Development.lean`; the proofs themselves live in the
auxiliary files of the project.

## Main statements

`sub_one_le_d` and `c_eq_zero_iff` (the two prose claims about `c`), `tsum_one_div_q_pow_c`
(Theorem 1), `sigma_infinite_iff` and `summable_one_div_q_pow_c` (Remark 1°),
`ncard_isomorphic_mul_w` (Remark 3°), and `tsum_one_div_w_mul_q_pow_c` (Theorem 2).

The objects they are stated over—`q`, `integers`, `IsTotallyRamified`, `sigma`, `discIdeal`, `d`,
`c`, `w`, `IsRepresentativeSet`—are defined in `Defs.lean`.

## Implementation notes

Modeling decisions, shared by `Defs.lean` and every auxiliary file of the project:

- The local field `K` is Mathlib's `IsNonarchimedeanLocalField K` over a `ValuativeRel` and a
  complete `UniformSpace`; Mathlib's instances then make `𝒪[K]` a complete DVR with finite residue
  field `𝓀[K]`, which is exactly the paper's standing hypothesis, covering mixed and equal
  characteristic alike.
- The residue cardinality is `q K = Nat.card 𝓀[K]`, and the residue characteristic `p` is written
  inline as `ringChar 𝓀[K]`.
- The separable closure is `SeparableClosure K`, and a subextension `L` of `SeparableClosure K` /
  `K` is a term of `IntermediateField K (SeparableClosure K)`.
- The ring of integers of `L` is `integers L`, the integral closure of `𝒪[K]` in `L`; its maximal
  ideal is modeled instance-freely as `maximalIdealAbove L`, the radical of `𝓂[K]` extended to
  `integers L`, and *totally ramified* means `ramificationIdx L = Module.finrank K ↥L`.
- All of this is junk-tolerant: for `L` infinite over `K` (or `n = 0`) the values are junk, and
  membership in `sigma K n` with `0 < n` is what keeps statements honest.
- `d L` is the multiplicity of `𝓂[K]` in the hand-rolled discriminant ideal `discIdeal L` (the span
  of the discriminants of the integral `K`-bases of `L`, following
  [Serre 1979, Chap. III, §3][Serre1979]), avoiding the freeness and Dedekind-domain instances that
  Mathlib's `differentIdeal` route would demand inside a total definition.
- `c L = d L - n + 1` is defined with truncated `ℕ`-subtraction as `d L + 1 - n`; the paper's claim
  that `c L` is a nonnegative integer becomes the goal `sub_one_le_d`.
- Theorems 1 and 2 are stated in `ℝ≥0∞`, where the possibly infinite `∑'` needs no convergence side
  condition and equality with the finite value `n` (resp. `1`) already encodes convergence; the
  convergence claim of Remark 1° is restated separately over `ℝ` as `Summable`.
- The paper's set of representatives is not built as a quotient: Theorem 2 instead quantifies over
  every `R` satisfying `IsRepresentativeSet n R`—the paper's "set of representatives of the
  isomorphism classes" verbatim—which avoids `Quotient.lift` well-definedness obligations for `c`
  and `w`.
- The aside that `q K ^ c L` is the norm of the wild component of the discriminant is interpretive
  prose and gets no formal statement; Remark 2° (Krasner's determination of the number of `L` in
  `sigma K n` with given `c L`) is a historical pointer and gets none either.

## References

Page references `p.N` follow the pagination of the working English translation
`blurbs/trans/Serre1978.en.tex` (repo-root-relative); the original journal page is `1030 + N`.

* [Serre1978] J-P. Serre, *Une «formule de masse» pour les extensions totalement ramifiées de
  degré donné d'un corps local*, C. R. Acad. Sci. Paris **286** (1978), Série A, 1031–1036.
* [Serre1979] J-P. Serre, *Local fields*, Graduate Texts in Mathematics **67**, Springer, 1979.

## Tags

local field, totally ramified extension, mass formula, discriminant, Serre
-/

open ValuativeRel MassFormula
open scoped ENNReal

namespace MassFormulaChallenge

variable (K : Type*) [Field K] [ValuativeRel K] [UniformSpace K] [IsUniformAddGroup K]
  [IsNonarchimedeanLocalField K]

/-- Let `d L` be the discriminant exponent of a finite extension `L` over `K`, and let `c L` be the
integer `d L - n + 1`, where `n` is the extension degree of `L` / `K`.  Then `c L` is an integer
`≥ 0` ([Serre 1978, p.1][Serre1978]). -/
theorem sub_one_le_d (n : ℕ) (hn : 0 < n) (L : IntermediateField K (SeparableClosure K))
    (hL : L ∈ sigma K n) : n - 1 ≤ d L :=
  sorry

/-- `c L = 0` if and only if `n` is prime to `p`, in other words if and only if the extension
`L` / `K` is tamely ramified ([Serre 1978, p.1][Serre1978]). -/
theorem c_eq_zero_iff (n : ℕ) (hn : 0 < n) (L : IntermediateField K (SeparableClosure K))
    (hL : L ∈ sigma K n) : c L = 0 ↔ ¬ ringChar 𝓀[K] ∣ n :=
  sorry

/-! ## The first mass formula -/

/-- The sum of `1 / (q K : ℝ≥0∞) ^ c L.1` over all `L` in `sigma K n` equals `n`
([Serre 1978, Theorem 1][Serre1978]). -/
theorem tsum_one_div_q_pow_c (n : ℕ) (hn : 0 < n) :
    ∑' L : sigma K n, 1 / (q K : ℝ≥0∞) ^ c L.1 = n :=
  sorry

/-- `sigma K n` is infinite exactly when `K` has equal characteristic `p` and `p` divides `n`;
in all other cases it is finite ([Serre 1978, Remark 1°][Serre1978]). -/
theorem sigma_infinite_iff (n : ℕ) (hn : 0 < n) :
    (sigma K n).Infinite ↔ ringChar K = ringChar 𝓀[K] ∧ ringChar 𝓀[K] ∣ n :=
  sorry

/-- The series with general term `1 / (q K : ℝ) ^ c L.1` is convergent—summability over `ℝ`,
meaningful also in the infinite case ([Serre 1978, Remark 1°][Serre1978]). -/
theorem summable_one_div_q_pow_c (n : ℕ) (hn : 0 < n) :
    Summable fun L : sigma K n => 1 / (q K : ℝ) ^ c L.1 :=
  sorry

/-! ## The second mass formula -/

/-- Every `L` in `sigma K n` is isomorphic to `n` / `w L` elements of `sigma K n`.  In multiplied
form, the number of `M` in `sigma K n` that are `K`-isomorphic to `L`, times `w L`, is `n`
([Serre 1978, Remark 3°][Serre1978]). -/
theorem ncard_isomorphic_mul_w (n : ℕ) (hn : 0 < n) (L : IntermediateField K (SeparableClosure K))
    (hL : L ∈ sigma K n) :
    ({M ∈ sigma K n | Nonempty (↥L ≃ₐ[K] ↥M)}).ncard * w L = n :=
  sorry

/-- The mass formula in the following form: the sum of `1 / ((w M.1 : ℝ≥0∞) * (q K : ℝ≥0∞) ^ c M.1)`
over all `M` in `R` equals `1`, where `R` is any set of representatives of the isomorphism classes
of the elements of `sigma K n` ([Serre 1978, Theorem 2][Serre1978]). -/
theorem tsum_one_div_w_mul_q_pow_c (n : ℕ) (hn : 0 < n)
    (R : Set (IntermediateField K (SeparableClosure K))) (hR : IsRepresentativeSet n R) :
    ∑' M : R, 1 / ((w M.1 : ℝ≥0∞) * (q K : ℝ≥0∞) ^ c M.1) = 1 :=
  sorry

end MassFormulaChallenge
