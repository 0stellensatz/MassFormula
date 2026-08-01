import Mathlib

/-!
# Statement of the result

The mass formula for the totally ramified extensions of given degree of a local field: Theorem 1,
over the set `sigma K n` of such extensions inside a fixed separable closure, and Theorem 2, its
reformulation over a set of representatives of the isomorphism classes, together with the
surrounding prose claims and remarks ([Serre 1978][Serre1978]).

This is the project's frozen specification: it declares one target per claim of the source, each
proved by `sorry`, over its own clones of the definitions they mention. It imports Mathlib and
nothing else, so the file is self-contained and free of any proof of what it asks for—the benchmark
the project offers (`__docs__/rules-comparator.md`). The same declarations, discharged, are in
`Development.lean`; the proofs themselves live in the auxiliary files of the project.

## Main statements

`sub_one_le_d` and `c_eq_zero_iff` (the two prose claims about `c`), `tsum_one_div_q_pow_c` (Theorem
1), `sigma_infinite_iff` and `summable_one_div_q_pow_c` (Remark 1°), `ncard_isomorphic_mul_w`
(Remark 3°), and `tsum_one_div_w_mul_q_pow_c` (Theorem 2).

The objects they are stated over—`q`, `integers`, `maximalIdealAbove`, `ramificationIdx`,
`IsTotallyRamified`, `sigma`, `discIdeal`, `d`, `c`, `w`, `IsRepresentativeSet`—are cloned into the
comparator namespace below, from the copies `Defs.lean` keeps under `MassFormula` for the auxiliary
files to build on.

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

## References

* [Serre1978] J-P. Serre, *Une «formule de masse» pour les extensions totalement ramifiées de
  degré donné d'un corps local*, C. R. Acad. Sci. Paris **286** (1978), Série A, 1031–1036.
* [Serre1979] J-P. Serre, *Local fields*, Graduate Texts in Mathematics **67**, Springer, 1979.

## Tags

local field, totally ramified extension, mass formula, discriminant, Serre
-/

open ValuativeRel
open scoped ENNReal

namespace MassFormulaChallenge

section CloneBlock

/-! ## The project's own definitions

Clones, into the comparator namespace, of the definitional layer the targets below are stated
over. `Defs.lean` carries the same declarations under `MassFormula`, for the auxiliary files to
build on; every one of them is a `def`, so a clone here is definitionally equal to its original
and a proof in `Development.lean` delegates across the boundary without conversion.

The bodies must stay identical to `Defs.lean`'s, and neither Lean nor `__check__.py` checks that,
so copy rather than retype (`__docs__/rules-comparator.md`). The two `rfl`-level lemmas of
`Defs.lean`, `one_lt_q` and `mem_sigma`, are not cloned: no target mentions them. -/

variable (K : Type*) [Field K] [ValuativeRel K] [UniformSpace K] [IsUniformAddGroup K]
  [IsNonarchimedeanLocalField K]

/-- `q K` is the cardinality of the finite residue field `𝓀[K]` of `K`, that is `Nat.card 𝓀[K]`
([Serre 1978, p.1031][Serre1978]). -/
noncomputable def q : ℕ :=
  Nat.card 𝓀[K]

variable {K}

/-- The ring of integers of a subextension `L` of `SeparableClosure K` / `K`: the integral closure
of `𝒪[K]` in `L` ([Serre 1978, §3, p.1032][Serre1978]). (Introduced by the paper only in Section 3,
but needed already here to say what *totally ramified* means.) -/
noncomputable def integers (L : IntermediateField K (SeparableClosure K)) :
    Subalgebra ↥𝒪[K] ↥L :=
  integralClosure ↥𝒪[K] ↥L

/-- The maximal ideal of `integers L`, modeled instance-freely as the radical of the ideal `𝓂[K]`
extended along `algebraMap 𝒪[K] (integers L)`. For `L` / `K` finite this is the unique maximal ideal
of the local ring `integers L`, but the definition itself carries no such obligations, and is junk
for `L` infinite over `K`. -/
noncomputable def maximalIdealAbove (L : IntermediateField K (SeparableClosure K)) :
    Ideal (integers L) :=
  (Ideal.map (algebraMap 𝒪[K] (integers L)) 𝓂[K]).radical

/-- The ramification index of `L` / `K`: the exponent of `maximalIdealAbove L` in the extension of
`𝓂[K]` to `integers L`, via Mathlib's junk-tolerant `Ideal.ramificationIdx'`. -/
noncomputable def ramificationIdx (L : IntermediateField K (SeparableClosure K)) : ℕ :=
  Ideal.ramificationIdx' 𝓂[K] (maximalIdealAbove L)

/-- `L` / `K` is *totally ramified* when its ramification index equals its degree
`Module.finrank K ↥L` ([Serre 1978, p.1031][Serre1978]). -/
def IsTotallyRamified (L : IntermediateField K (SeparableClosure K)) : Prop :=
  ramificationIdx L = Module.finrank K ↥L

variable (K)

/-- The set of subextensions `L` of `SeparableClosure K` that are totally ramified over `K` and
satisfy `Module.finrank K ↥L = n` ([Serre 1978, p.1031][Serre1978]). For `n = 0` the set is junk
(the paper takes `1 ≤ n`), which is why every statement of the comparator carries `0 < n`. -/
def sigma (n : ℕ) : Set (IntermediateField K (SeparableClosure K)) :=
  {L | Module.finrank K ↥L = n ∧ IsTotallyRamified L}

variable {K}

/-- The discriminant ideal of a subextension: the ideal of `𝒪[K]` generated by the elements whose
image in `K` is `Algebra.discr K b` for some `K`-basis `b` of `L` with all entries integral over
`𝒪[K]` (cf. [Serre 1979, Chap. III, §3][Serre1979]). When `L` / `K` is finite separable this is the
classical discriminant ideal generated by the discriminants of the `𝒪[K]`-bases of `integers L`: an
integral `K`-basis spans a sublattice of finite index in `integers L`, and the discriminant of that
sublattice is the square of the index times the discriminant of `integers L`. The present form needs
no freeness or Dedekind-domain instances. For `L` infinite over `K` no such basis exists and the
ideal is `⊥`—junk, as usual. -/
noncomputable def discIdeal (L : IntermediateField K (SeparableClosure K)) : Ideal ↥𝒪[K] :=
  Ideal.span {x : ↥𝒪[K] | ∃ b : Module.Basis (Fin (Module.finrank K ↥L)) K ↥L,
    (∀ i, IsIntegral 𝒪[K] (b i)) ∧ algebraMap 𝒪[K] K x = Algebra.discr K ⇑b}

/-- The valuation of the discriminant of `L` over `K`: the multiplicity of the maximal ideal `𝓂[K]`
in `discIdeal L`, in the monoid of ideals of `𝒪[K]` ([Serre 1978, p.1031][Serre1978]). -/
noncomputable def d (L : IntermediateField K (SeparableClosure K)) : ℕ :=
  multiplicity 𝓂[K] (discIdeal L)

/-- `c L` is `d L - n + 1`, where `n` is the degree `Module.finrank K ↥L`, written in the
truncation-safe form `d L + 1 - n` ([Serre 1978, p.1031][Serre1978]). The bound `n - 1 ≤ d L` making
the truncated subtraction faithful is the paper's own claim that `c L` is a nonnegative integer, the
goal `sub_one_le_d` of the comparator. -/
noncomputable def c (L : IntermediateField K (SeparableClosure K)) : ℕ :=
  d L + 1 - Module.finrank K ↥L

/-- The number of `K`-automorphisms of `L` ([Serre 1978, Remark 3°, p.1031][Serre1978]). -/
noncomputable def w (L : IntermediateField K (SeparableClosure K)) : ℕ :=
  Nat.card (↥L ≃ₐ[K] ↥L)

/-- The paper's set of representatives, as a predicate rather than a quotient: `R` is a *set of
representatives of the isomorphism classes of the elements of* `sigma K n`—it consists of elements
of `sigma K n`, and every element of `sigma K n` is `K`-isomorphic to exactly one member of `R`
([Serre 1978, Remark 3°, p.1031][Serre1978]). -/
def IsRepresentativeSet (n : ℕ) (R : Set (IntermediateField K (SeparableClosure K))) : Prop :=
  R ⊆ sigma K n ∧ ∀ L ∈ sigma K n, ∃! M, M ∈ R ∧ Nonempty (↥L ≃ₐ[K] ↥M)

end CloneBlock

variable (K : Type*) [Field K] [ValuativeRel K] [UniformSpace K] [IsUniformAddGroup K]
  [IsNonarchimedeanLocalField K]

/-- Let `d L` be the discriminant exponent of a finite extension `L` over `K`, and let `c L` be the
integer `d L - n + 1`, where `n` is the extension degree of `L` / `K`.  Then `c L` is an integer
`≥ 0` ([Serre 1978, p.1031][Serre1978]). -/
theorem sub_one_le_d (n : ℕ) (hn : 0 < n) (L : IntermediateField K (SeparableClosure K))
    (hL : L ∈ sigma K n) : n - 1 ≤ d L :=
  sorry

/-- `c L = 0` if and only if `n` is prime to `p`, in other words if and only if the extension
`L` / `K` is tamely ramified ([Serre 1978, p.1031][Serre1978]). -/
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
