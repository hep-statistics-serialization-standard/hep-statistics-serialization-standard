# Add FFT and decay convolution distributions

## Summary

This PR specifies two convolution distributions with related terminology but
different input contracts:

- `fft_convolution_dist` references general source and kernel distributions;
- `decay_convolution_dist` directly contains a restricted exponential decay
  profile and an inline `gaussian`, `delta`, or `mixture` kernel.

An FFT convolution has the outer components `name`, `type`, `x`, `source`, and
`kernel`. A decay convolution has the flat outer components `name`, `type`,
`x`, `envelope`, `terms`, and `kernel`. The decay representation introduces no
helper source distribution or function node.

The design grew out of
[ROOT issue #22770](https://github.com/root-project/root/issues/22770), but the
HS<sup>3</sup> representation is independent of ROOT. It describes the model
inputs without exposing implementation-specific constructors, basis codes, or
computation graphs.

Category-indexing semantics are outside this PR. Category-dependent
coefficients can use the facility proposed in
[HS3 PR #119](https://github.com/hep-statistics-serialization-standard/hep-statistics-serialization-standard/pull/119)
after that proposal is accepted. This PR does not duplicate or modify that
facility.

## Motivation

`analytic_convolution_dist` suggested a general analytical-convolution
facility, although its portable input vocabulary described a much narrower
family of exponential decay profiles. Renaming it to
`decay_convolution_dist` states that scope directly and does not make the
evaluation strategy part of the model's identity.

The previous nested source also separated summands and coefficients into
parallel arrays. The revised representation makes the decay components direct
members of the distribution and pairs each coefficient with its basis. This
removes an avoidable nesting level and makes every additive term locally
complete.

## Mathematical contract

For a continuous convolution variate \(x\), source density \(S\), and kernel
\(K\), both convolution types represent

\[
q(x)=\int_{-\infty}^{\infty}S(u)K(x-u)\,du,
\qquad
p(x)=\frac{q(x)}{\mathcal M}.
\]

The inner integral spans the full real line. The outer normalization
\(\mathcal M\) follows the current HS<sup>3</sup> domain. Both convolution
types are non-extended; event yields use the existing extended-distribution
mechanism.

The resulting density must be finite and non-negative throughout its domain
and must not be identically zero.

## FFT convolution

An FFT convolution has:

- `name`: custom unique string;
- `type`: `fft_convolution_dist`;
- `x`: convolution variate;
- `source`: source-distribution reference; and
- `kernel`: kernel-distribution reference.

The source and kernel must be non-extended distributions and must both use
`x` as their convolution variate.

```json
{
  "name": "smeared_signal",
  "type": "fft_convolution_dist",
  "x": "mass",
  "source": "unsmeared_signal",
  "kernel": "detector_response"
}
```

## Decay convolution

A decay convolution has:

- `name`: custom unique string;
- `type`: `decay_convolution_dist`;
- `x`: convolution variate;
- `envelope`: inline exponential-envelope object;
- `terms`: non-empty array of inline decay terms; and
- `kernel`: inline kernel object.

There is no separate source node. The envelope and terms directly define the
unconvolved profile

\[
S(u)=E(u)A(u),
\qquad
A(u)=\sum_{i=1}^{n}c_iB_i(u).
\]

### Exponential envelope

`envelope` contains a positive `scale` and a `support` equal to `positive`,
`negative`, or `both`. It has no `type`: every envelope in this distribution
is exponential. For \(\tau=\text{scale}\), the alternatives are

\[
E_+(u;\tau)=\mathbf 1_{u\geq0}e^{-u/\tau},\qquad
E_-(u;\tau)=\mathbf 1_{u\leq0}e^{u/\tau},\qquad
E_{\pm}(u;\tau)=e^{-|u|/\tau}.
\]

### Additive terms

Every entry of `terms` contains exactly:

- `coefficient`: a number or real-valued parameter or function reference
  representing \(c_i\); and
- `basis`: a supported inline basis object representing \(B_i\).

The conversion from serialized terms to the additive sum is direct. For each
entry, multiply the value of `coefficient` by the function represented by
`basis`; then add all of those products:

\[
\left[
  \{\text{coefficient}:c_1,\text{basis}:B_1\},\ldots,
  \{\text{coefficient}:c_n,\text{basis}:B_n\}
\right]
\quad\longmapsto\quad
A(u)=c_1B_1(u)+\cdots+c_nB_n(u).
\]

A `constant` basis represents \(B_i(u)=1\) and has no other component. A
`sin`, `cos`, `sinh`, or `cosh` basis contains `rate` and represents
\(B_i(u)=g(\text{rate}\,u)\). Derived rates are represented by ordinary
function references.

The scale, rates, and coefficients must be independent of `x`. Individual
coefficients may be negative, but the complete unconvolved and convolved
densities must be finite, non-negative, and nonzero.

### Simple decay with a delta kernel

```json
{
  "name": "two_sided_decay",
  "type": "decay_convolution_dist",
  "x": "decay_time",
  "envelope": {
    "scale": "lifetime",
    "support": "both"
  },
  "terms": [
    {
      "coefficient": 1.0,
      "basis": {"type": "constant"}
    }
  ],
  "kernel": {"type": "delta"}
}
```

### Four-term decay with a Gaussian kernel

```json
{
  "name": "four_term_decay",
  "type": "decay_convolution_dist",
  "x": "decay_time",
  "envelope": {
    "scale": "lifetime",
    "support": "positive"
  },
  "terms": [
    {
      "coefficient": "cosh_coefficient",
      "basis": {"type": "cosh", "rate": "half_delta_gamma"}
    },
    {
      "coefficient": "sinh_coefficient",
      "basis": {"type": "sinh", "rate": "half_delta_gamma"}
    },
    {
      "coefficient": "cos_coefficient",
      "basis": {"type": "cos", "rate": "delta_mass"}
    },
    {
      "coefficient": "sin_coefficient",
      "basis": {"type": "sin", "rate": "delta_mass"}
    }
  ],
  "kernel": {
    "type": "gaussian",
    "mean": "time_bias",
    "sigma": "time_resolution_width"
  }
}
```

### Inline kernels

The kernel catalog contains:

- `{"type": "gaussian", "mean": ..., "sigma": ...}`, with positive
  `sigma`;
- `{"type": "delta"}`; and
- `{"type": "mixture", "summands": [...], "coefficients": [...]}`.

A mixture recursively contains inline kernels. For \(n\) summands, it contains
either \(n\) coefficients that sum to one or \(n-1\) coefficients, with the
last coefficient defined as \(1-\sum_{i=1}^{n-1}c_i\). Every explicit and
implicit coefficient must be non-negative. Kernel parameters must be
independent of `x`.

```json
{
  "name": "mixture_smeared_decay",
  "type": "decay_convolution_dist",
  "x": "decay_time",
  "envelope": {
    "scale": "lifetime",
    "support": "positive"
  },
  "terms": [
    {
      "coefficient": 1.0,
      "basis": {"type": "constant"}
    }
  ],
  "kernel": {
    "type": "mixture",
    "summands": [
      {"type": "gaussian", "mean": 0.0, "sigma": "core_width"},
      {"type": "gaussian", "mean": 0.0, "sigma": "tail_width"}
    ],
    "coefficients": ["core_fraction"]
  }
}
```

## ROOT source assessment

The current ROOT sources were inspected to verify coverage. These class names
are implementation notes and do not appear in the normative HS<sup>3</sup>
catalog.

| ROOT class | Representation in this proposal |
|---|---|
| `RooFFTConvPdf` | `fft_convolution_dist` with referenced source and kernel distributions. |
| `RooDecay` | One `constant` term with positive, negative, or two-sided exponential support. |
| `RooBDecay` | Four terms using `cosh`, `sinh`, `cos`, and `sin` bases. |
| `RooBMixDecay` | Decay terms whose category-dependent coefficient functions are supplied by PR #119. |
| `RooBCPGenDecay` | Decay terms with coefficient functions supplied by PR #119 where categories are required. |
| `RooBCPEffDecay` | The same basis catalog, with model dependence carried by coefficient functions. |
| `RooNonCPEigenDecay` | Hyperbolic and oscillatory bases with coefficient functions. |
| `RooGaussModel` | Embedded `gaussian` kernel. |
| `RooTruthModel` | Embedded `delta` kernel. |
| `RooAddModel` | Embedded `mixture` kernel. |

Each `basis` determines one expression registered through `declareBasis()`.
Its paired `coefficient` supplies the value returned by the implementation's
coefficient interface. The representation therefore preserves the required
decomposition without serializing ROOT's basis codes or internal convolution
nodes.

## Relationship to PR #119

Several B-physics distributions select coefficients using categorical
observables. This PR permits every term coefficient to reference a real-valued
function, which is the composition point needed by those models. PR #119 owns
the representation and validation of category-dependent functions. No
category-indexing type, mapping rule, or JSON example is introduced here.

## Breaking migration from earlier drafts

HS<sup>3</sup> is pre-1.0, so the earlier forms are replaced rather than kept
as aliases:

| Earlier representation | Translation |
|---|---|
| `fft_convolution_dist` with `pdf1`, `pdf2`, and `conv_var` | Rename these to `source`, `kernel`, and `x`. Drop `conv_func`, `ipOrder`, and numerical cache controls. |
| `analytic_convolution_dist` with an inline `source` | Rename the type to `decay_convolution_dist`. Move `source.factor.scale` and `source.factor.support` to `envelope`, omitting the redundant exponential type. Pair each old coefficient and summand as one entry in `terms`. Translate a numeric constant summand to a `constant` basis and absorb its numeric value into the coefficient. |
| `decay_dist` | Place its lifetime and support in `envelope` and create one `constant` term. |
| `gauss_model_function` | Embed a `gaussian` kernel in each consuming decay convolution. |
| `truth_model_function` | Embed a `delta` kernel in each consuming decay convolution. |
| `mixture_model` | Embed normalized resolution components in a `mixture` kernel. Move any event yield to an extended-distribution wrapper around the completed convolution. |

No ROOT implementation is changed by this PR.

## Invalid representations made explicit

The normative text rejects:

- extended or mismatched FFT source and kernel distributions;
- an empty `terms` array;
- terms without exactly one coefficient and one supported basis;
- envelope, basis, coefficient, or kernel parameters that are required to be
  independent of `x` but depend on it;
- non-positive envelope scales or Gaussian widths;
- empty kernel mixtures, negative weights, invalid coefficient counts, and
  explicitly supplied weights that do not sum to one; and
- unconvolved or convolved densities that are non-finite, negative, or
  identically zero.

## Review questions

1. Does `decay_convolution_dist` communicate the intentionally restricted
   model family more clearly than `analytic_convolution_dist`?
2. Is the flat `envelope`, `terms`, and `kernel` structure preferable to a
   nested source object?
3. Does pairing `coefficient` and `basis` make the construction of the
   additive sum sufficiently explicit?
4. Are `constant`, `sin`, `cos`, `sinh`, and `cosh` the right initial basis
   catalog?
5. Are `gaussian`, `delta`, and recursive `mixture` the right initial inline
   kernel catalog?
