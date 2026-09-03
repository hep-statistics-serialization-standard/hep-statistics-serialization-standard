# Add a shared convolution contract and an analytic convolution profile

## Summary

This PR introduces two distinct convolution distributions with a common outer
shape:

```json
{
  "name": "smeared_model",
  "type": "fft_convolution_dist or analytic_convolution_dist",
  "x": "observable",
  "distribution": "source",
  "kernel": "distribution reference or inline analytic kernel"
}
```

- `fft_convolution_dist` is the general representation and references two
  distributions.
- `analytic_convolution_dist` is an optimized representation for a portable
  factorized source and an embedded `gaussian`, `delta`, or `mixture` kernel.
- `factorized_sum` is a function, not another distribution. The existing
  `density_function_dist` supplies normalization.

The design grew out of
[ROOT issue #22770](https://github.com/root-project/root/issues/22770), but the
HS<sup>3</sup> contract is intentionally independent of ROOT. Implementations
should adapt to the standard rather than exposing implementation-specific
constructor and cache options in the wire format.

Category-indexing semantics are outside this PR. Category-dependent
coefficients can be composed with the facility proposed in
[HS3 PR #119](https://github.com/hep-statistics-serialization-standard/hep-statistics-serialization-standard/pull/119)
after that proposal is accepted. This PR does not duplicate or modify that
facility.

## Motivation

The previous draft mirrored the internal organization of analytical decay
classes too closely: it placed a resolution model in the distribution catalog
and stored a list of convolution-specific basis terms directly in the final
distribution. That made analytical and FFT convolutions look unrelated even
though they implement the same mathematical operation.

The revised design separates three reusable concepts:

1. a source distribution;
2. a convolution kernel; and
3. an algorithm or portable profile used to evaluate their convolution.

Authors should use FFT convolution for arbitrary sources and kernels. The
analytic type is appropriate only when the source and kernel match its small,
portable catalog.

## Mathematical contract

For a continuous convolution variate \(x\), source density \(f\), and kernel
\(K\), both distribution types represent

\[
q(x)=\int_{-\infty}^{\infty} f(u)K(x-u)\,du,
\qquad
p(x)=\frac{q(x)}{\mathcal M}.
\]

The inner integral spans the full real line. The outer normalization
\(\mathcal M\) follows the current HS<sup>3</sup> domain. Both convolution
types are non-extended; event yields use the existing extended-distribution
mechanism.

The result must be finite and non-negative throughout its domain and must not
be identically zero. An implementation supporting the analytic type may
reject profiles outside the catalog below; it is not required to fall back to
numerical convolution.

## FFT convolution

An FFT convolution has `name`, `type`, `x`, `distribution`, and `kernel`.
Both operands reference non-extended distributions that use the same
convolution variate:

```json
{
  "name": "smeared_signal",
  "type": "fft_convolution_dist",
  "x": "mass",
  "distribution": "unsmeared_signal",
  "kernel": "detector_response"
}
```

Transform grids, buffer regions, interpolation orders, and caches affect an
implementation's numerical accuracy but not the represented probability
model. They are therefore not serialized by this type.

## Analytic convolution

The analytic form uses the same five outer fields. Its `distribution`
references a `density_function_dist` whose density is a `factorized_sum`, and
its `kernel` is embedded:

```json
{
  "functions": [
    {
      "name": "decay_profile",
      "type": "factorized_sum",
      "x": "decay_time",
      "factor": {
        "type": "exponential",
        "scale": "lifetime",
        "support": "both"
      },
      "summands": [1.0],
      "coefficients": [1.0]
    }
  ],
  "distributions": [
    {
      "name": "unsmeared_decay",
      "type": "density_function_dist",
      "function": "decay_profile"
    },
    {
      "name": "two_sided_decay",
      "type": "analytic_convolution_dist",
      "x": "decay_time",
      "distribution": "unsmeared_decay",
      "kernel": {"type": "delta"}
    }
  ]
}
```

### Factorized source

The function

\[
F(x)\sum_{i=1}^{n} c_iG_i(x)
\]

is serialized using the `factor`, `summands`, and `coefficients` fields. The
last two arrays have equal length. Coefficients are independent of `x`, while
the common factor and summands may depend on `x`.

For analytic convolution, `factor` is an inline exponential with a positive
`scale` and `support` equal to `positive`, `negative`, or `both`:

\[
F_+(x;\tau)=\mathbf 1_{x\geq0}e^{-x/\tau},\qquad
F_-(x;\tau)=\mathbf 1_{x\leq0}e^{x/\tau},\qquad
F_{\pm}(x;\tau)=e^{-|x|/\tau}.
\]

The analytic summands are constants or inline `sin`, `cos`, `sinh`, and
`cosh` objects with a `rate`. Each represents \(g(\text{rate}\,x)\). Derived
rates are ordinary functions; for example, a model can define
`half_delta_gamma` separately and reference it from `rate`.

The canonical factorization is what enables portable analytic dispatch. More
general densities can continue to use ordinary `sum`, `product`, and generic
function graphs and can be convolved with `fft_convolution_dist`.

### Embedded kernel catalog

Analytic kernels have no `name` or `x`; both are inherited from the containing
distribution.

- `{"type": "gaussian", "mean": ..., "sigma": ...}` represents a
  normalized Gaussian kernel and requires a positive width.
- `{"type": "delta"}` represents perfect resolution.
- `{"type": "mixture", "summands": [...], "coefficients": [...]}`
  recursively combines embedded kernels.

For \(n\) mixture summands, either \(n\) normalized coefficients or \(n-1\)
coefficients are serialized. In the latter case, the final coefficient is
\(1-\sum_{i=1}^{n-1}c_i\). Every weight must be non-negative.

```json
{
  "name": "smeared_decay",
  "type": "analytic_convolution_dist",
  "x": "decay_time",
  "distribution": "unsmeared_decay",
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

### Four-term decay example

The initial source catalog covers the exponential, hyperbolic, and
oscillatory structure needed by the targeted B-physics models:

```json
{
  "functions": [
    {
      "name": "four_term_profile",
      "type": "factorized_sum",
      "x": "decay_time",
      "factor": {
        "type": "exponential",
        "scale": "lifetime",
        "support": "positive"
      },
      "summands": [
        {"type": "cosh", "rate": "half_delta_gamma"},
        {"type": "sinh", "rate": "half_delta_gamma"},
        {"type": "cos", "rate": "delta_mass"},
        {"type": "sin", "rate": "delta_mass"}
      ],
      "coefficients": [
        "cosh_coefficient",
        "sinh_coefficient",
        "cos_coefficient",
        "sin_coefficient"
      ]
    }
  ],
  "distributions": [
    {
      "name": "four_term_source",
      "type": "density_function_dist",
      "function": "four_term_profile"
    },
    {
      "name": "four_term_decay",
      "type": "analytic_convolution_dist",
      "x": "decay_time",
      "distribution": "four_term_source",
      "kernel": {
        "type": "gaussian",
        "mean": "time_bias",
        "sigma": "time_resolution_width"
      }
    }
  ]
}
```

## ROOT source assessment

The current ROOT sources were inspected to verify coverage. These class names
are implementation notes and do not appear in the normative HS<sup>3</sup>
catalog.

| ROOT class | Representation in this proposal |
|---|---|
| `RooFFTConvPdf` | `fft_convolution_dist`; constructor and cache controls remain implementation details. |
| `RooDecay` | One constant summand with positive, negative, or two-sided exponential support. |
| `RooBDecay` | Four summands using `cosh`, `sinh`, `cos`, and `sin`. |
| `RooBMixDecay` | Factorized decay source; category-dependent coefficient functions are supplied by PR #119. |
| `RooBCPGenDecay` | Factorized decay source with coefficient functions supplied by PR #119 where categories are required. |
| `RooBCPEffDecay` | The same source catalog, with model dependence carried by coefficient functions. |
| `RooNonCPEigenDecay` | Hyperbolic and oscillatory summands with coefficient functions. |
| `RooGaussModel` | Embedded `gaussian` kernel. |
| `RooTruthModel` | Embedded `delta` kernel. |
| `RooAddModel` | Embedded `mixture` kernel. |

This proposal deliberately does not serialize the internal basis identifiers,
proxy layout, interpolation order, transformed convolution coordinate, or
cache settings used by the current implementation.

## Relationship to PR #119

Several B-physics distributions select coefficients using categorical
observables. This PR permits every coefficient to reference a real-valued
function, which provides the composition point needed by those models. PR
#119 owns the representation and validation of category-dependent functions.
No category-indexing type, mapping rule, or JSON example is introduced here.

## Breaking migration from earlier drafts

HS<sup>3</sup> is pre-1.0, so the earlier special cases are replaced rather
than retained as aliases:

| Earlier representation | Translation |
|---|---|
| `fft_convolution_dist` with `pdf1`, `pdf2`, and `conv_var` | Rename these to `distribution`, `kernel`, and `x`. Drop `conv_func`, `ipOrder`, and numerical cache controls. |
| `decay_dist` | Create a `factorized_sum`, wrap it in `density_function_dist`, and reference it from `analytic_convolution_dist`. Translate the old direction to `positive`, `both`, or `negative` support. |
| `gauss_model_function` | Embed a `gaussian` kernel in each consuming analytic convolution. |
| `truth_model_function` | Embed a `delta` kernel in each consuming analytic convolution. |
| `mixture_model` | Embed normalized resolution components in a `mixture` kernel. Move any event yield to an extended-distribution wrapper around the completed convolution. |

No ROOT implementation is changed by this PR.

## Invalid representations made explicit

The normative text rejects:

- extended or mismatched convolution operands;
- an empty factorized sum or unequal summand and coefficient counts;
- coefficients or analytic profile parameters that depend on `x`;
- analytic sources outside the initial factor and summand catalog;
- non-positive exponential scales or Gaussian widths;
- empty kernel mixtures, negative weights, invalid coefficient counts, and
  explicitly supplied weights that do not sum to one; and
- final densities that are non-finite, negative, or identically zero.

## Review questions

1. Is `x`, `distribution`, and `kernel` the right shared vocabulary for both
   convolution types?
2. Is FFT convolution the appropriate default for sources or kernels outside
   the portable analytic profile?
3. Does `density_function_dist` plus `factorized_sum` keep normalization and
   analytic dispatch sufficiently separate?
4. Are `gaussian`, `delta`, and recursive `mixture` the right initial inline
   kernel catalog?
5. Should transformed convolution coordinates or standardized numerical
   accuracy controls be considered in a later proposal?
6. Is replacing the earlier pre-1.0 special cases preferable to retaining
   temporary aliases?
