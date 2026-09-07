# Add a shared convolution contract and a self-contained analytic profile

## Summary

This PR introduces two distinct convolution distributions with the shared
outer components `name`, `type`, `x`, `source`, and `kernel`.

- `fft_convolution_dist` references a source distribution and a kernel
  distribution.
- `analytic_convolution_dist` embeds a restricted source description and a
  `gaussian`, `delta`, or `mixture` kernel.

The design grew out of
[ROOT issue #22770](https://github.com/root-project/root/issues/22770), but the
HS<sup>3</sup> representation is independent of ROOT. It describes the model
inputs needed for convolution without exposing implementation-specific
constructors or computation graphs.

Category-indexing semantics are outside this PR. Category-dependent
coefficients can use the facility proposed in
[HS3 PR #119](https://github.com/hep-statistics-serialization-standard/hep-statistics-serialization-standard/pull/119)
after that proposal is accepted. This PR does not duplicate or modify that
facility.

## Motivation

The previous draft placed resolution models in the distribution catalog and
stored a list of implementation-shaped basis objects directly in the final
distribution. It also made analytical and FFT convolutions look unrelated,
despite representing the same mathematical operation.

The revised design uses `source` and `kernel` consistently as the two roles in
a convolution. FFT convolution references general distributions. Analytic
convolution embeds the restricted source decomposition and kernel information
needed by specialized implementations. The analytic object is therefore
self-contained and introduces no helper distribution or function type.

## Mathematical contract

For a continuous convolution variate \(x\), source density \(S\), and kernel
\(K\), both types represent

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

An FFT convolution has the following components:

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

## Analytic convolution

An analytic convolution uses the same outer component names, but `source` and
`kernel` are inline objects:

```json
{
  "name": "two_sided_decay",
  "type": "analytic_convolution_dist",
  "x": "decay_time",
  "source": {
    "factor": {
      "type": "exponential",
      "scale": "lifetime",
      "support": "both"
    },
    "summands": [1.0],
    "coefficients": [1.0]
  },
  "kernel": {"type": "delta"}
}
```

Neither inline object has a `name` or `x`; both inherit the convolution
variate from their containing distribution.

### Inline source

The source represents

\[
S(u)=F(u)\sum_{i=1}^{n}c_iG_i(u).
\]

It contains:

- `factor`: the common exponential factor \(F\);
- `summands`: a non-empty array of constants or supported inline functions
  \(G_i\); and
- `coefficients`: an equally sized array of numbers or real-valued parameter
  or function references \(c_i\).

The exponential factor has a positive `scale` and `support` equal to
`positive`, `negative`, or `both`:

\[
F_+(u;\tau)=\mathbf 1_{u\geq0}e^{-u/\tau},\qquad
F_-(u;\tau)=\mathbf 1_{u\leq0}e^{u/\tau},\qquad
F_{\pm}(u;\tau)=e^{-|u|/\tau}.
\]

Supported non-constant summands have `type` equal to `sin`, `cos`, `sinh`, or
`cosh` and a `rate`. Such an object represents
\(G_i(u)=g(\text{rate}\,u)\). Derived rates are represented by ordinary
function references.

The scale, rates, and coefficients must be independent of `x`. Individual
coefficients may be negative, but the complete source density must be finite,
non-negative, and nonzero.

### Inline kernel

The initial kernel catalog contains:

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
  "name": "smeared_decay",
  "type": "analytic_convolution_dist",
  "x": "decay_time",
  "source": {
    "factor": {
      "type": "exponential",
      "scale": "lifetime",
      "support": "positive"
    },
    "summands": [1.0],
    "coefficients": [1.0]
  },
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

The source catalog covers the exponential, hyperbolic, and oscillatory
structure required by the targeted B-physics models:

```json
{
  "name": "four_term_decay",
  "type": "analytic_convolution_dist",
  "x": "decay_time",
  "source": {
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
  },
  "kernel": {
    "type": "gaussian",
    "mean": "time_bias",
    "sigma": "time_resolution_width"
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
| `RooDecay` | One constant summand with positive, negative, or two-sided exponential support. |
| `RooBDecay` | Four summands using `cosh`, `sinh`, `cos`, and `sin`. |
| `RooBMixDecay` | Inline decay source; category-dependent coefficient functions are supplied by PR #119. |
| `RooBCPGenDecay` | Inline decay source with coefficient functions supplied by PR #119 where categories are required. |
| `RooBCPEffDecay` | The same source catalog, with model dependence carried by coefficient functions. |
| `RooNonCPEigenDecay` | Hyperbolic and oscillatory summands with coefficient functions. |
| `RooGaussModel` | Embedded `gaussian` kernel. |
| `RooTruthModel` | Embedded `delta` kernel. |
| `RooAddModel` | Embedded `mixture` kernel. |

Each inline summand and the common factor determine one basis expression for
`declareBasis()`. The corresponding source coefficient supplies the value
returned by the implementation's coefficient interface. This preserves the
decomposition required by analytical resolution kernels without serializing
ROOT's basis codes or internal convolution nodes.

## Relationship to PR #119

Several B-physics distributions select coefficients using categorical
observables. This PR permits every source coefficient to reference a
real-valued function, which is the composition point needed by those models.
PR #119 owns the representation and validation of category-dependent
functions. No category-indexing type, mapping rule, or JSON example is
introduced here.

## Breaking migration from earlier drafts

HS<sup>3</sup> is pre-1.0, so the earlier special cases are replaced rather
than retained as aliases:

| Earlier representation | Translation |
|---|---|
| `fft_convolution_dist` with `pdf1`, `pdf2`, and `conv_var` | Rename these to `source`, `kernel`, and `x`. Drop `conv_func`, `ipOrder`, and numerical cache controls. |
| `decay_dist` | Place its exponential envelope and constant summand directly in the analytic `source`; translate the old direction to `positive`, `both`, or `negative` support. |
| `gauss_model_function` | Embed a `gaussian` kernel in each consuming analytic convolution. |
| `truth_model_function` | Embed a `delta` kernel in each consuming analytic convolution. |
| `mixture_model` | Embed normalized resolution components in a `mixture` kernel. Move any event yield to an extended-distribution wrapper around the completed convolution. |

No ROOT implementation is changed by this PR.

## Invalid representations made explicit

The normative text rejects:

- extended or mismatched FFT source and kernel distributions;
- an empty analytic source or unequal summand and coefficient counts;
- source or kernel parameters that are required to be independent of `x` but
  depend on it;
- source factors or summands outside the initial catalog;
- non-positive exponential scales or Gaussian widths;
- empty kernel mixtures, negative weights, invalid coefficient counts, and
  explicitly supplied weights that do not sum to one; and
- source or convolved densities that are non-finite, negative, or identically
  zero.

## Review questions

1. Is `x`, `source`, and `kernel` the right shared vocabulary for both
   convolution types?
2. Does embedding `factor`, `summands`, and `coefficients` make the analytic
   type sufficiently self-contained?
3. Is the restricted source decomposition sufficient for independent
   implementations to construct their analytical bases?
4. Are `gaussian`, `delta`, and recursive `mixture` the right initial inline
   kernel catalog?
5. Is replacing the earlier pre-1.0 special cases preferable to retaining
   temporary aliases?
