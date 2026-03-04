#import "/docs/hs3-defs.typ": sc
// Chapter 2.1.2: Composite Distributions

=== Composite distributions

This section contains composite distributions in the sense that they refer to other distribution which they combine or modify in some way.

==== Mixture distribution

The mixture distribution, sometimes called addition of distributions, is a (weighted) sum of distributions $f_i (arrow(x))$, depending on the same variable(s) $arrow(x)$:

$ "MixturePdf"(x) = frac(1, cal(M)) sum_(i=1)^n c_i dot f_i (arrow(x)), $

where the $c_i$ are coefficients and $arrow(x)$ is the vector of variables.

- `name`: custom unique string
- `type`: `mixture_dist`
- `name`: name of the variable $x$ (#sc[optional], since the variable is fully defined by the summands)
- `summands`: array of names referencing distributions
- `coefficients`: array of names of coefficients $c_i$ or numbers to be added
- `extended`: boolean denoting whether this is an extended distribution (#sc[optional], as it can be inferred from the lengths of the lists for `summands` and `coefficients`)

This distribution can be treated as extended or as non-extended.

- If the number of coefficients equals the number of distributions and `extended` is `false`, then the sum of the coefficient must be (approximately) one.
- If the number of coefficients equals the number of distributions and `extended` is `true`, then the sum of the coefficients will be used as the Poisson rate parameter and the mixture distribution itself will use the coefficients normalized by their sum.
- If the number of coefficients is one less than the number of distributions, then `extended` must be `false` and $c_n$ is computed from the other coefficients as

$ c_n = 1 - sum_(i=1)^(n-1) c_i . $

==== Product distribution <sec:product-distribution>

The product of independent distributions $f_i$ is defined as

$ "ProductPdf"(x) = frac(1, cal(M)) product_i^n f(x). $

- `name`: custom string
- `type`: `product_dist`
- `x`: name of the variable $x$ (#sc[optional], since the variable is fully defined by the factors)
- `factors`: array of names referencing distributions

==== Density Function distribution

A distribution that is specified via a non-normalized density function $f(x)$. Formally, it corresponds to the probability measure that has the density $f(x)$ in respect to the Lebesgue measure.

The density function is normalized automatically by $cal(M) = integral f(x) d x$, so the PDF of the distribution is

$ "DensityFunctionPdf"(f, x) = frac(f(x), cal(M)) $

The distribution can be specified either via the non-normalized density function $f(x)$ or via the non-normalized log-density function $log(f(x))$:

- `density_function_dist`: Specified via the PDF $f(x)$
  - `name`: custom string
  - `type`: `density_function_dist`
  - `function`: The density function $f$
- `log_density_function_dist`: Specified via the log-PDF $log(f(x))$
  - `name`: custom string
  - `type`: `log_density_function_dist`
  - `function`: The density function $f$

==== Poisson point process <dist:poisson-point-process>

A Poisson point process distribution is understood here as the distribution of the outcomes of a (typically inhomogeneous) Poisson point process. In particle physics, such a distribution is often called an extended distribution @barlow-extended-ml.

In HS#super[3], a Poisson point process distribution is specified using a global-rate parameter $lambda$ and an underlying distribution $m$, either explicitly or implicitly (see below).

Random values are drawn from the Poisson point process distribution by drawing a random number $n$ from a Poisson distribution of the global-rate $lambda$, and then drawing $n$ random values from the underlying distribution $m$. The resulting random values are vectors $x$ of length $n$, so their length varies.

The PDF the Poisson point process distribution at an outcome $x$ (a vector of length $n$) is

$ "PoissonPointProcessPdf"(lambda, m, x) = "PoissonPdf"(n, lambda) dot product_i^n "PDF"(m, x_i). $

In particle physics, the function $"PoissonPointProcessPdf"(lambda, m(theta), x)$, for a fixed observation $x$ and varying parameters $lambda$ and $theta$, is often called an extended likelihood.

A Poisson point process distribution can be specified in HS#super[3] in two ways:

- `rate_extended_dist`: The global-rate parameter $lambda$ and underlying distribution $m$ are specified explicitly:
  - `name`: custom string
  - `type`: `rate_extended_dist`
  - `rate`: The global rate $lambda$
  - `dist`: The underlying distribution $m$

  The name of the variable $x$ is taken from the underlying distribution. The underlying distribution #sc[must] not be referred to from other components of the statistical model.

- `rate_density_dist`: Specified via a non-normalized rate-density function $f$. Both the global-rate parameter and the underlying distribution are implicit: $lambda = integral f(y) d y$ and $m = "DensityFunctionPdf"(f)$. More formally, the distribution corresponds to the inhomogeneous Poisson point process that is defined by a non-normalized rate measure which has density $f$ in respect to the Lebesque measure.
  - `name`: custom string
  - `type`: `rate_density_dist`
  - `x`: name of the variable $x$
  - `density`: The rate-density function $f$

==== Bin-count distribution <dist:bin-counts>

This is a binned version of the Poisson point process distribution (@dist:poisson-point-process). It is the distribution of the bin counts that result from histogramming the outcomes of a Poisson point process distribution using a given binning scheme (see @sec:binned-data).

Like the Poisson point process distribution, a Bin-counts distribution can either be specified via a global-rate parameter $lambda$ and an underlying distribution $m$, or via a rate-density function $f$ (in which case $lambda$ and $m$ are implicit). In addition, the binning scheme also has to be specified in either case, unless it can be inferred (see below).

For $k$ bins, this type of distribution corresponds to a product of $k$ Poisson distributions with rates

$ nu_i &= lambda dot integral_("bin"_i) "PDF"(y, m) d y quad "equivalent to" \
  nu_i &= integral_("bin"_i) f(y) d y $

The PDF of the bin-counts distribution at an outcome $x$ (a vector of length $k$, same as the number of bins) is

$ "BinCountsPdf"(x) = product_i^k "PoissonPdf"(x_i, nu_i) $

- `bincounts_extended_dist`: The global-rate parameter $lambda$ and underlying distribution $m$ are specified explicitly:
  - `name`: custom string
  - `type`: `bincounts_extended_dist`
  - `rate`: The global rate $lambda$
  - `dist`: The underlying distribution $m$
  - `axes`: a definition of the binning to be used, following the definitions in @sec:binned-data. #sc[optional] if `dist` is a binned distribution, in which case the same binning is used by default.

  The name of the variable $x$ is taken from the underlying distribution. The underlying distribution #sc[must] not be referred to from other components of the statistical model.

- `bincounts_density_dist`: Specified via a non-normalized rate-density function $f$. Both the global-rate parameter and the underlying distribution are implicit: $lambda = integral f(y) d y$ and $m = "DensityFunctionPdf"(f)$.

  More formally, the distribution corresponds to the inhomogeneous Poisson point process that is defined by a non-normalized rate measure which has density $f$ in respect to the Lebesque measure.

  - `name`: custom string
  - `type`: `bincounts_density_dist`
  - `x`: name of the variable $x$
  - `density`: The rate-density function $f$
  - `axes`: a definition of the binning to be used, following the definitions in @sec:binned-data.
