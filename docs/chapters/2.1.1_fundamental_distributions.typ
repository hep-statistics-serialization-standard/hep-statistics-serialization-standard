#import "/docs/hs3-defs.typ": sc
// Chapter 2.1.1: Fundamental Distributions

=== Univariate fundamental distributions

This section contains univariate fundamental distributions in the
sense that they cannot refer to any other distribution -- only to
functions, parameters and exactly one variable.

==== Argus distribution

The Argus background distribution is defined as

$ "ArgusPdf"(m, m_0, c, p) = frac(1, cal(M)) dot m dot lr([1 - lr((frac(m, m_0)))^2])^p dot exp lr([c dot lr((1 - lr((frac(m, m_0)))^2))]) $

and describes the ARGUS background shape.

- `name`: custom unique string
- `type`: `argus_dist`
- `mass`: name of the variable $m$ used as mass
- `resonance`: value or name of the parameter used as resonance $m_0$
- `slope`: value or name of the parameter used as slope $c$
- `power`: value or name of the parameter used as exponent $p$.

==== Continued Poisson distribution

The continued Poisson distribution of the variable $x$ is defined as

$ "ContinuedPoissonPdf"(x, lambda) = frac(1, cal(M)) exp(x dot ln lambda - lambda - ln Gamma(x+1)), $

where $Gamma$ denotes the Euler Gamma function.

This function is similar the the Poisson distribution (see @dist:poisson), but can accept non-integer values for $x$. Notably, the differences between the two might be significant for small values of $x$ (below x). Nevertheless, the distribution is useful to deal with datasets with non-integer event counts, such as Asimov datasets @asymptotics.

- `name`: custom unique string
- `type`: `poisson_dist`
- `x`: name of the variable $x$ (usually referred to as $k$ for the standard integer case)
- `mean`: value or name of the parameter used as mean $lambda$.

==== Uniform distribution

The continuous uniform distribution is defined as:

$ "UniformPdf"(x) = frac(1, cal(M)) $

- `name`: custom unique string
- `type`: `uniform_dist`
- `x`: name of the variable $x$

==== Crystal Ball distribution

The generalized Asymmetrical Double-Sided Crystal Ball line shape,
composed of a Gaussian distribution at the core, connected with two
power-law distributions describing the lower and upper tails, given by

$ "CrystalBallPdf"(m; m_0, sigma, alpha_L, n_L, alpha_R, n_R) = frac(1, cal(M)) cases(
  A_L dot (B_L - frac(m - m_0, sigma_L))^(-n_L) &"for" frac(m - m_0, sigma_L) < -alpha_L,
  exp(-frac(1, 2) dot [frac(m - m_0, sigma_L)]^2) &"for" frac(m - m_0, sigma_L) <= 0,
  exp(-frac(1, 2) dot [frac(m - m_0, sigma_R)]^2) &"for" frac(m - m_0, sigma_R) <= alpha_R,
  A_R dot (B_R + frac(m - m_0, sigma_R))^(-n_R) &"otherwise",
) $

where

$ A_i &= (frac(n_i, |alpha_i|))^(n_i) dot exp(-frac(|alpha_i|^2, 2)) \
  B_i &= frac(n_i, |alpha_i|) - |alpha_i| $

The keys are

- `name`: custom string
- `type`: `crystalball_dist`
- `m`: name of the variable $m$
- `m0`: name or value of the central value $m_0$
- `alpha`: value or names of $alpha_L$ and $alpha_R$ from above. #sc[must not] be used in conjunction with `alpha_L` or `alpha_R`.
- `alpha_L`: value or names of $alpha_L$ from above. #sc[must not] be used in conjunction with `alpha`.
- `alpha_R`: value or names of $alpha_R$ from above. #sc[must not] be used in conjunction with `alpha`.
- `n`: value or names of $n_L$ and $n_R$ from above. #sc[must not] be used in conjunction with `n_L` or `n_R`.
- `n_L`: value or names of $n_L$ from above. #sc[must not] be used in conjunction with `n`.
- `n_R`: value or names of $n_R$ from above. #sc[must not] be used in conjunction with `n`.
- `sigma`: value or names of $sigma_L$ and $sigma_R$ from above. #sc[must not] be used in conjunction with `sigma_L` or `sigma_R`.
- `sigma_L`: value or names of $sigma_L$ from above. #sc[must not] be used in conjunction with `sigma`.
- `sigma_R`: value or names of $sigma_R$ from above. #sc[must not] be used in conjunction with `sigma`.

==== Exponential distribution

The exponential distribution is defined as

$ "ExponentialPdf"(x, c) = frac(1, cal(M)) dot exp(-c dot x) $

- `name`: custom unique string
- `type`: `exponential_dist`
- `x`: name of the variable $x$
- `c`: value or name of the parameter used as coefficient $c$.

==== Gaussian/normal distribution

The Gaussian/normal distribution is defined as

$ "GaussianPdf"(x, mu, sigma) = frac(1, cal(M)) exp(-frac((x - mu)^2, 2 sigma^2)) $

- `name`: custom unique string
- `type`: `gaussian_dist` _or_ `normal_dist`
- `x`: name of the variable $x$
- `mean`: value or name of the parameter used as mean value $mu$
- `sigma`: value or name of the parameter encoding the standard deviation $sigma$.

==== Generalized Normal distribution

The generalized normal distribution is defined as

$ "GeneralizedNormalPdf"(x, mu, alpha, beta) = frac(1, cal(M)) exp{-(frac(|x - mu|, alpha))^beta} $

cf. the #link("https://en.wikipedia.org/wiki/Generalized_normal_distribution")[Wikipedia definition].

This form is of particular use with values of $beta tilde 8$ to generate a flat-topped distribution useful for "2 point" parameter-constraints between models where there is no clear preference but their average should not be particularly favoured. (In such usage, the template points should ideally be located at $|x| < plus.minus 1$, to avoid disfavouring a pure solution.)

- `name`: custom unique string
- `type`: `generalized_normal_dist`
- `x`: name of the variable $x$
- `mean`: value or name of the parameter used as mean value $mu$
- `alpha`: value or name of the $alpha$ parameter encoding the width; this corresponds to $sigma = alpha \/ sqrt(2)$ when $beta = 2$.
- `beta`: power $beta$ to which the exponent is raised, $beta = 2$ corresponding to the $"GaussianPdf"$ shape.

==== Log-Normal distribution

The log-normal distribution is defined as

$ "LogNormalPdf"(x, mu, sigma) = frac(1, cal(M)) frac(1, x) exp(-frac((ln(x) - mu)^2, 2 sigma^2)) $

- `name`: custom unique string
- `type`: `lognormal_dist`
- `x`: name of the variable $x$
- `mu`: value or name of the parameter used as $mu$
- `sigma`: value or name of the parameter $sigma$ describing the shape

==== Poisson distribution <dist:poisson>

The Poisson distribution of the variable $x$ is defined as

$ "PoissonPdf"(x, lambda) = frac(1, cal(M)) frac(lambda^x, x!) e^(-lambda). $

where $x$ is required to be an integer.
In this case, the behavior for non-integer values of $x$ is undefined.

- `name`: custom unique string
- `type`: `poisson_dist`
- `x`: name of the variable $x$ (usually referred to as $k$ for the standard integer case)
- `mean`: value or name of the parameter used as mean $lambda$.

==== Polynomial distribution

The polynomial distribution is defined as

$ "PolynomialPdf"(x, a_0, a_1, a_2, ...) = frac(1, cal(M)) sum_(i=0)^n a_i x^i = a_0 + a_1 x + a_2 x^2 + ... $

- `name`: custom unique string
- `type`: `polynomial_dist`
- `x`: name of the variable $x$
- `coefficients`: array of coefficients $a_i$. The length of this array implies the degree of the polynomial.

=== Multivariate fundamental distributions

This section contains multivariate fundamental distributions. They may
refer to functions, parameters and more than one variable.

==== Barlow-Beeston-Lite Constraint distribution

This distribution represents a product of Poisson distributions
defining the statistical uncertainties of the histogram templates
defined in a `histfactory_func`.

$ "BarlowBeestonLitePoissonConstraintPdf"(x) = frac(1, cal(M)) product_(i)^n "PoissonPdf"(x_i dot tau_i, tau_i) $

- `name`: custom unique string
- `type`: `barlow_beeston_lite_poisson_constraint_dist`
- `x`: array of names of the variables $x_i$. This also includes mixed arrays of values and names.
- `expected`: array of central values $tau_i$

==== Multivariate normal distribution

The multivariate normal distribution is defined as

$ "MvNormalPdf"(bold(x), bold(mu), bold(Sigma)) = frac(1, cal(M)) exp(-frac(1, 2) (bold(x) - bold(mu))^top bold(Sigma)^(-1) (bold(x) - bold(mu))), $

with $bold(Sigma) in bb(R)^(k times k)$ being positive-definite.

- `name`: custom unique string
- `type`: `multivariate_normal_dist`
- `x`: array of names of the variables $bold(x)$. This also includes mixed arrays of values and names.
- `mean`: array of length $k$ of values or names of the parameters used as mean values $bold(mu)$
- `covariances`: an array comprised of $k$ sub-arrays, each of which is also of length $k$, designed to store values or names of the entries of the covariance matrix $bold(Sigma)$. In general, the covariance matrix $bold(Sigma)$ #sc[must] be symmetric and positive semi-definite.

==== Generic distribution

_Note: Users should prefer the specific distributions defined in this standard over generic distributions where possible, as implementations of these will typically be more optimized. Generic distributions should only be used if no equivalent specific distribution is defined._

A generic distribution is defined by an expression that represents the PDF of the distribution in respect to the Lebesgue measure. The expression must be a valid HS#super[3]-expression string (see @sec:generic_expression).

- `name`: custom string
- `type`: `generic_dist`
- `expression`: a string with a generic mathematical expression. Simple mathematical syntax common to most programming languages should be used here, such as `x-2*y+z`. The arguments `x`, `y` and `z` in this example #sc[must] be parameters, functions or variables.

The distribution is normalized by the implementation, so a normalization term #sc[should not] be included in the expression. If the expression results in a negative value, the behavior is undefined.

==== HistFactory distribution

#include "/docs/parts/histfactory.typ"

==== Relativistic Breit-Wigner distribution

The relativistic Breit-Wigner distribution describes the line-shape of a resonance in the mass spectrum of a two-particle system. It is assumed that the resonance can decay into a list of channels.

The first channel in the list indicates the system for which mass
distribution is modelled.

$ "BreitWignerPDF"(m, m_"BW") &= frac(1, cal(M)) frac(m Gamma_1(m), |m_"BW"^2 - m^2 - i m_"BW" Gamma(m)|^2), \
  Gamma(m) &= sum_i Gamma_i (m), $ <eq:relativistic_breit_wigner_dist>

When modelling the mass spectrum, the term $m$ in the numerator of @eq:relativistic_breit_wigner_dist accounts for a jacobian of transformation from $m^2$ to $m$. The width term $Gamma_1(m)$ adds for the phase space factor for the channel of interest

- `name`: custom unique string
- `type`: `relativistic_breit_wigner_dist`
- `mass`: name of the mass variable $m_"BW"$
- `channels`: list of `structs` encoding the channels

Each of the channels is defined by the partial width $Gamma_i (m)$, given as

$ Gamma_i (m) &= Gamma_("BW",i) n_(l i)^2 (m) rho_i (m), \
  rho_i (m) &= 2 q_i (m) \/ m, \
  q_i (m) &= sqrt((m^2 - (m_(1 i) + m_(2 i))^2)(m^2 - (m_(1 i) - m_(2 i))^2)) \/ (2m), \
  n_(l i)(m) &= z_i^(l i)(m) h_(l i)(z_i (m)), \
  z_i (m) &= q_i (m) R_i $

The $h_l (z)$ is the standard Blatt-Weisskopf form-factors, $h_0^2(z) = 1\/(1+z^2)$, $h_1^2(z) = 1\/(9+3z^2+z^4)$, and so on (Eqs.(50.30-50.35) in Ref.~@pdg2023). The `struct`s defining the channels should contain the following keys:

- `name`: name of the final state (#sc[optional])
- `Gamma`: partial width $Gamma_"BW"$ of the resonance
- `m1`: mass $m_1$ of the first particle the resonance decays into (default value $0$)
- `m2`: mass $m_2$ of the second particle the resonance decays into (default value $0$)
- `l`: orbital angular momentum $l$ (default value $0$)
- `R`: form-factor size parameter $R$ (default value $3$ GeV)

For non-zero angular momentum, $Gamma_i (m_"BW")$ gives an approximation to the partial width of the resonance, not $Gamma_("BW",i)$.
A commonly used approximation of the relativistic Breit-Wigner function with the constant width is a special case of @eq:relativistic_breit_wigner_dist, where the `[channels]` argument contains a single channel with $m_1 = 0$, $m_2 = 0$, and $l = 0$.
