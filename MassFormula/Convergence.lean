import Mathlib
import MassFormula.Defs
import MassFormula.First

open ValuativeRel
open scoped ENNReal

namespace MassFormula

/-!
# Auxiliary file: `summable_one_div_q_pow_c`—the convergence claim of Remark 1°

The paper remarks that even when `sigma K n` is infinite the series with general term
`1 / (q K : ℝ) ^ c L.1` is convergent ([Serre 1978, Remark 1°, p.1031][Serre1978]). Over `ℝ≥0∞` no
convergence claim is needed—the extended sum always exists—so the comparator restates the remark
over `ℝ` as `Summable`. The derivation runs through Theorem 1: by `tsum_one_div_q_pow_c` the
`ℝ≥0∞`-valued sum equals `n`, which is finite, and an `ℝ≥0∞`-valued family with finite sum has
summable `toReal`s (`ENNReal.summable_toReal`); identifying the terms is `toReal` arithmetic.

## References

* [Serre1978] J-P. Serre, *Une «formule de masse» pour les extensions totalement ramifiées de
  degré donné d'un corps local*, C. R. Acad. Sci. Paris **286** (1978), Série A, 1031–1036.
-/

variable (K : Type*) [Field K] [ValuativeRel K] [UniformSpace K] [IsUniformAddGroup K]
  [IsNonarchimedeanLocalField K]

/-- The series with general term `1 / (q K : ℝ) ^ c L.1` is convergent—the statement of
`Development.lean`'s `summable_one_div_q_pow_c`, derived from Theorem 1
([Serre 1978, Remark 1°, p.1031][Serre1978]). -/
theorem summable_one_div_q_pow_c (n : ℕ) (hn : 0 < n) :
    Summable fun L : sigma K n => 1 / (q K : ℝ) ^ c L.1 := by
  have h : ∑' L : sigma K n, 1 / (q K : ℝ≥0∞) ^ c L.1 ≠ ⊤ := by
    rw [tsum_one_div_q_pow_c K n hn]
    exact ENNReal.natCast_ne_top n
  refine (ENNReal.summable_toReal h).congr fun L => ?_
  simp [one_div, ENNReal.toReal_inv, ENNReal.toReal_pow, ENNReal.toReal_natCast]

end MassFormula
