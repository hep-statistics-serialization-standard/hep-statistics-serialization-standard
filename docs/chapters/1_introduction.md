---
bibliography: ./hs3.bib
---

# Introduction 
*This section is non-normative.* 
It is widely agreed upon that the publication of likelihood models from high energy physics experiments is imperative for the preservation and public access to these results. Detailed arguments have been made elsewhere already [@Cranmer_2022]. This document sets out to provide a standardized format to publish and archive statistical models of any size and across a wide range of mathematical formalisms in a way that is readable by both humans and machines. 
With the introduction of `pyhf` [@pyhf; @pyhf-joss], a `JSON` format for likelihood serialization has been put forward. However, an interoperable format that encompasses likelihoods with a scope beyond stacks of binned histograms was lacking. With the release of `ROOT` 6.26/00 [@root] and the experimental `RooJSONFactoryWSTool` therein, this gap has now been filled. 
This document sets out to document the syntax and features of the Statistics Serialization Standard (HS<sup>3</sup>) for likelihoods and statistical models in general, as to be adopted by any HS<sup>3</sup>-compatible statistics framework. The examples in this document employ the `JSON` notation, but are intended to encompass also representations as `YAML` or `TOML`. 

## How to use this document 
Developers of statistical toolkits are invited to specifically refer to versions of this document relating to the support of this standard in their respective implementations. 
Please note that this document as well as the HS<sup>3</sup> standard are still in development and can still undergo minor and major changes in the future. This document describes the syntax of HS<sup>3</sup> v0.2.9. 

## Statistical semantics of HS<sup>3</sup> {#sec:hs3-semantics} 

### Statistical models, probability distributions and parameters {#sec:models-and-parameters} 
HS<sup>3</sup> takes a "forward-modelling" approach throughout: a statistical model $m$ maps a space $\Theta$ of free parameters $\theta$ to a space of probability distributions that describe the possible outcomes of a specific experiment. For any given parameters $\theta$, the model returns a concrete probability distribution $m(\theta)$. Observed data $x$ is then treated as random variate, presumed to be drawn from the model: $x \sim m(\theta)$. 
Parameters in HS<sup>3</sup> are always named, so semantically the elements of a parameter space $\Theta$ are named tuples $\theta$ (meaning tuples in which every entry has a name). Even if there is only a single free parameter, $\theta$ should be thought of as a single-entry named tuple. In the current version of this standard, parameter tuples must be flat and only consist of real numbers, vector-valued or nested entries are not supported yet. Future versions of the standard will likely be less restrictive, especially with respect to discrete or vector-valued parameters. Parameter domains defined as part of this standard may be of various types, even though the current version only supports product domains. Future versions are likely to be less restrictive in this regard. 
Mathematically and computationally, it is often convenient to treat parameters as flat real-valued vectors instead of named tuples, it is the responsibility of the implementation to map between these different views of parameters when and where necessary. 
Probability distributions in HS<sup>3</sup> (see 
[\[sec:distributions\]](#sec:distributions){reference-type="ref" reference="sec:distributions"}) are typically parameterized. Any instance of a distribution that has some of its parameters bound to names instead of concrete values, e.g. $m = d_{\mu = a, \sigma = 0.7, \lambda = b, ...}$, constitutes a valid statistical model $m(\theta)$ with model parameters $\theta = (a, b)$. 
When probability distributions are combined via a Cartesian product (see 
[\[sec:product-distribution\]](#sec:product-distribution){reference-type="ref" reference="sec:product-distribution"}), then the named tuples that contain their free parameter values are concatenated. So $m = d_{\mu = a, \sigma = b} \times d_{\mu = c, \sigma = 0.7}$ constitutes a model $m(\theta)$ with model parameters $\theta = (a, b, c)$. 
Distribution parameters may also be bound to the output of functions, and if those functions have inputs that are bound to names instead of values (or again bound to such functions, recursively), then those names become part of the model parameters. A configuration $m = d_{\mu = a, \sigma = 0.7, \lambda = f}, f = sum(4.2, g), g = sum(1.3, b)$, for example, also constitutes a (different) model $m(\theta)$ with parameters $\theta = (a, b, c)$. 
If all parameter values of a probability distribution are set to concrete values, so if there are not directly (or indirectly via functions) bound to names, we call this probability distribution a concrete distribution here. Such distributions can be used as Bayesian 
priors (see [1.2.6](#sec:bayesian-inference){reference-type="ref" reference="sec:bayesian-inference"}). 
The variates of all distributions (so the possible results of random draws from them) are also named tuples in all cases. So even instances of univariate distributions, like the normal distributions, have variates like $(x = \ldots)$. The names in the variate tuples can be configured for each instance of a distribution, and must be unique across all distributions that are used together in a model. In Cartesian products of distributions, their variate tuples are concatenated. As with parameter tuples, nested tuples are not supported. The tuple entries, however, may be vector-valued, in contrast to parameter tuples. 

### Probability density functions (PDFs) {#sec:what-is-a-pdf} 
Statistics literature often discriminates between probability density functions (PDF) for continuous probability distributions and probability mass functions (PMF) for discrete probability distributions. This standard use the term PDF for both continuous and discrete distributions. The concept of density is to be understood in terms of densities in the realm of measure theory here, that is the density of a probability measure (distribution) is its Radon-Nikodym derivative in respect to an (implied) reference measure. 
The choice of reference measure would be arbitrary in principle, which scales likelihood functions 
(Sec.&nbsp;[1.2.4](#sec:likelihood-definition){reference-type="ref" reference="sec:likelihood-definition"}) by a constant factor that depends on choice of reference. In this standard, a specific reference measures is implied for each probability distribution, typically the Lebesgue measure for continuous distributions and the counting measure for discrete distributions. The standard aims to to match the PDF (resp.&nbsp;PMF) most commonly used in literature for each specific probability distribution and the mathematical form of the PDF is documented explicitly for each distribution in the standard. So within HS<sup>3</sup>, probability densities and likelihood functions are unambiguous. 
Here we use $\text{PDF}(m(\theta), x)$ to denote the density value of the probability distribution/measure $m$, parameterized by $\theta$, at the point/variate $x$, in respect to the implied reference for $m$. 

### Observed and simulated data {#sec:data-generation} 
The term data refers here to any collection of values that represents the outcome of an experiment. Data takes the same form as variates of distributions (see 
[\[sec:distributions\]](#sec:distributions){reference-type="ref" reference="sec:distributions"}, i. e.&nbsp;named tuple of real values or vectors. To compare given data with a given model, the names and shapes of the data entries must match the variates of the probability distributions $m(\theta)$ that the model returns for a specific choice of parameters $\theta$. 
This means that given a model $m$ and concrete parameter values $\theta$, drawing a set of random values from the probability distribution $m(\theta)$ produces a valid set of simulated observations. Implementations can use this to provide mock-data generation capabilities. 

### Likelihood functions {#sec:likelihood-definition} 
The concrete probability distribution $m(\theta)$ that a model $m$ returns for specific parameter values $\theta$ can be compared to observed data $x$. This gives rise to a likelihood $\mathcal{L}_{m,x}(\theta) = \text{PDF}(m(\theta), x)$ that is a real-valued function on the parameter space. Multiple distributions/models that describe different modes of observation can be combined with multiple sets of data that cover those modes of observation into a single likelihood (Sec. 
[\[sec:likelihoods\]](#sec:likelihoods){reference-type="ref" reference="sec:likelihoods"}). In addition to using observed data, implementations may provide the option to use random data generated from 
the model (see [1.2.3](#sec:data-generation){reference-type="ref" reference="sec:data-generation"}) to check for Monte-Carlo closure. 

### Frequentist parameter inference {#sec:frequentist-inference} 
The standard method of frequentist inference is the maximum (or, respectively, profile) likelihood method. In the vast majority of cases, the test statistic used here is the likelihood ratio, that is, the ratio of two values of the likelihood corresponding to two different points in parameter space: one that maximizes the likelihood unconditionally, one one that maximizes the likelihood under some condition such as the values of the parameters of interest expected in the absence of a deviation from the null hypothesis. The corresponding building blocks for such an analysis, such as the list of parameters of interest and the likelihood function to be used, are specified in the analysis section of an HS<sup>3</sup> configuration (Sec. 
[\[sec:analyses\]](#sec:analyses){reference-type="ref" reference="sec:analyses"}). 

### Bayesian parameter inference {#sec:bayesian-inference} 
The standard also encompasses the specification of Baysian posterior distributions over parameters by combining (Sec. 
[\[sec:analyses\]](#sec:analyses){reference-type="ref" reference="sec:analyses"}) likelihoods with probabilty distributions that acts the priors. Here concrete distributions are used to describe the prior probability of parameters in addition to parameterized distributions that are used to describe of the probability of observing specific data. 

## How to read this document 
In the context of this document, any `JSON` object is referred to as a struct. A key-value-pair inside such a struct is referred to as a component. If not explicitly stated otherwise, all components mentioned are mandatory. 
The components located inside the top-level struct are referred to as top-level components. 
The keywords [optional]{.smallcaps} and [required]{.smallcaps}, as well as [should]{.smallcaps} and [may]{.smallcaps} are used in accordance with IETF requirement levels [@rfc2119]. 

## Terms and Types 
This is a list of used types and terms in this document. 
-   `struct`: represented with { }, containing a *key:value* mapping,     keys are of type `string`. 
-   `component`: key-value pair within a struct 
-   `array] array of items (either ``string``s or ``number``s) without keys. Represented with [ `: 
-   `string`: references to objects, names and arbitrary information.     Represented with 
-   `number`: either floating or integer type values 
-   `boolean`: boolean values; they can be encoded as `true` and `false` 
All `struct`s defining functions, distributions, parameters, variables, domains, likelihoods, data or parameter points will be referred to as `object`s. All `object`s [must]{.smallcaps} always have a component `name` that [must]{.smallcaps} be unique among all `object`s. 
Within most top-level `component`s, any one `string` given as a value to any component [should]{.smallcaps} refer to the `name` of another `object`, unless explicitly stated otherwise. Top-level `component`s in which this is not the case are explicitly marked as such. 

## File format 
HS3 documents are encoded in the JSON format as defined in ISO/IEC 21778:2017 [@json]. Implementations [may]{.smallcaps} support other serialization formats that support a non-ambiguous mapping to JSON, such as TOML or YAML, in which case they [should]{.smallcaps} use a different file extension. 

## Validators 
Future versions of this standard will recommend official validator implementations and schemata. Currently, these have not been finalized. 

## How to get in touch 
<https://github.com/hep-statistics-serialization-standard/hep-statistics-serialization-standard> 
