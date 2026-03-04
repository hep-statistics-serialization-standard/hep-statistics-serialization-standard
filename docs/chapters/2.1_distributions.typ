#import "/docs/hs3-defs.typ": sc
// Chapter 2.1: Distributions

== Distributions <sec:distributions>

The top-level component `distributions` contains an array of distributions in struct format. Distributions #sc[must] be normalized, thus, the letter $cal(M)$ in the following descriptions will always relate to the normalization of the distribution. The value of $cal(M)$ is conditional on the current domain. It #sc[must] be chosen such that the integral of the distribution over the current domain equals one. The implementations might chose to perform this integral using analytical or numerical means.

Each distribution #sc[must] have the components `type`, denoting the kind of distribution described, and a component `name`, which acts as a unique identifier of this distribution among all other named objects. Distributions in general have the following keys:

- `name`: custom unique string (#sc[required]), e.g.~`my_distribution_of_x`
- `type`: string (#sc[required]) that determines the kind of distribution, e.g.~`gaussian_dist`
- `...`: each distribution #sc[may] have components for the various individual parameters. For example, distributions of type `gaussian_dist` have the specific components `mean`, `sigma` and `x`. In general, these components #sc[may] be strings as references to other `objects`, but #sc[may] also directly yield numeric or boolean values. Depending on the parameter and the type of distribution, they appear either in single item or array format.

#figure(caption: [Example: Distributions])[
```json
"distributions":[
  {
    "name":"gauss1",
    "type":"gaussian_dist",
    "mean":1.0,
    "sigma":"param_sigma",
    "x":"param_x"
  },
  {
    "name":"exp1",
    "type":"exponential_dist",
    "c":-2,
    "x":"data_x"
  },
  ...
]
```
]

Distributions can be treated either as `extended` or as non-`extended` @barlow-extended-ml. Some distributions are always extended, others can never be extended, yet others can be used in extended and non-extended scenarios and have a switch selecting between the two. An non-extended distribution is always normalized to the unity. An extended distribution, on the other hand, can yield values larger than unity, where the yield is interpreted as the number of predicted events. That is to say, the distribution is augmented by a factor that is a Poisson constraint term for the total number of events.

In the following, all distributions supported in HS#super[3] v0.2.9 are listed in detail. Future versions will expand upon this list.
