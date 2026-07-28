import Mathlib
import MassFormula.Convergence
import MassFormula.Defs
import MassFormula.Discriminant
import MassFormula.Finiteness
import MassFormula.First
import MassFormula.Orbit
import MassFormula.Second
import MassFormula.Tame

/-!
# Statement of the result, discharged

The Development half of the comparator pair: the declaration list of `Challenge.lean` verbatim—same
names, kinds, binders, types, and docstrings—with the bodies replaced by the proofs of the auxiliary
files.

Only the imports and the bodies may differ from `Challenge.lean`. A body still unproved stays
`sorry`; when an auxiliary file discharges it, the `sorry` here becomes a one-line delegation and
the statement is left untouched. See `__docs__/rules-comparator.md`. The mathematical narrative, the
modeling decisions, and the references are in `Challenge.lean` and are not repeated here.
-/

open ValuativeRel MassFormula
open scoped ENNReal

namespace MassFormulaChallenge

variable (K : Type*) [Field K] [ValuativeRel K] [UniformSpace K] [IsUniformAddGroup K]
  [IsNonarchimedeanLocalField K]

/-- Let `d L` be the discriminant exponent of a finite extension `L` over `K`, and let `c L` be the
integer `d L - n + 1`, where `n` is the extension degree of `L` / `K`. Then `c L` is an integer
`≥ 0` ([Serre 1978, p.1][Serre1978]). -/
theorem sub_one_le_d (n : ℕ) (hn : 0 < n) (L : IntermediateField K (SeparableClosure K))
    (hL : L ∈ sigma K n) : n - 1 ≤ d L :=
  MassFormula.sub_one_le_d K n hn L hL

/-- `c L = 0` if and only if `n` is prime to `p`, in other words if and only if the extension
`L` / `K` is tamely ramified ([Serre 1978, p.1][Serre1978]). -/
theorem c_eq_zero_iff (n : ℕ) (hn : 0 < n) (L : IntermediateField K (SeparableClosure K))
    (hL : L ∈ sigma K n) : c L = 0 ↔ ¬ ringChar 𝓀[K] ∣ n :=
  MassFormula.c_eq_zero_iff K n hn L hL

/-! ## The first mass formula -/

/-- The sum of `1 / (q K : ℝ≥0∞) ^ c L.1` over all `L` in `sigma K n` equals `n`
([Serre 1978, Theorem 1][Serre1978]). -/
theorem tsum_one_div_q_pow_c (n : ℕ) (hn : 0 < n) :
    ∑' L : sigma K n, 1 / (q K : ℝ≥0∞) ^ c L.1 = n :=
  MassFormula.tsum_one_div_q_pow_c K n hn

/-- `sigma K n` is infinite exactly when `K` has equal characteristic `p` and `p` divides `n`;
in all other cases it is finite ([Serre 1978, Remark 1°][Serre1978]). -/
theorem sigma_infinite_iff (n : ℕ) (hn : 0 < n) :
    (sigma K n).Infinite ↔ ringChar K = ringChar 𝓀[K] ∧ ringChar 𝓀[K] ∣ n :=
  MassFormula.sigma_infinite_iff K n hn

/-- The series with general term `1 / (q K : ℝ) ^ c L.1` is convergent—summability over `ℝ`,
meaningful also in the infinite case ([Serre 1978, Remark 1°][Serre1978]). -/
theorem summable_one_div_q_pow_c (n : ℕ) (hn : 0 < n) :
    Summable fun L : sigma K n => 1 / (q K : ℝ) ^ c L.1 :=
  MassFormula.summable_one_div_q_pow_c K n hn

/-! ## The second mass formula -/

/-- Every `L` in `sigma K n` is isomorphic to `n` / `w L` elements of `sigma K n`.  In multiplied
form, the number of `M` in `sigma K n` that are `K`-isomorphic to `L`, times `w L`, is `n`
([Serre 1978, Remark 3°][Serre1978]). -/
theorem ncard_isomorphic_mul_w (n : ℕ) (hn : 0 < n) (L : IntermediateField K (SeparableClosure K))
    (hL : L ∈ sigma K n) :
    ({M ∈ sigma K n | Nonempty (↥L ≃ₐ[K] ↥M)}).ncard * w L = n :=
  MassFormula.ncard_isomorphic_mul_w K n hn L hL

/-- The mass formula in the following form: the sum of `1 / ((w M.1 : ℝ≥0∞) * (q K : ℝ≥0∞) ^ c M.1)`
over all `M` in `R` equals `1`, where `R` is any set of representatives of the isomorphism classes
of the elements of `sigma K n` ([Serre 1978, Theorem 2][Serre1978]). -/
theorem tsum_one_div_w_mul_q_pow_c (n : ℕ) (hn : 0 < n)
    (R : Set (IntermediateField K (SeparableClosure K))) (hR : IsRepresentativeSet n R) :
    ∑' M : R, 1 / ((w M.1 : ℝ≥0∞) * (q K : ℝ≥0∞) ^ c M.1) = 1 :=
  MassFormula.tsum_one_div_w_mul_q_pow_c K n hn R hR

end MassFormulaChallenge
