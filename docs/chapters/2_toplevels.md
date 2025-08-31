---
bibliography: ./hs3.bib
---


# Top-level components {#sec:toplevel} 
In the followingc the top-level `component`s of HS$^3$ and their parameters/arguments are described. Each component is completely [optional]{.smallcaps}, but certain components [may]{.smallcaps} depend on other components, which [should]{.smallcaps} be provided in that case. The only exception is the component `metadata` containing the version of HS$^3$, which is always [required]{.smallcaps}. The supported top-level components are 

-   [`distributions`](#sec:distributions): ([optional]{.smallcaps})     array of `object`s defining distributions 

-   [`functions`](#sec:functions): ([optional]{.smallcaps}) array of     `object`s defining mathematical functions 

-   [`data`](#sec:data): ([optional]{.smallcaps}) array of `objects`     defining observed or simulated data 

-   [`likelihoods`](#sec:likelihoods): ([optional]{.smallcaps}) array of     `object`s defining combinations of distributions and data 

-   [`domains`](#sec:domains): ([optional]{.smallcaps}) array of     `object`s defining domains, describing ranges of parameters 

-   [`parameter_points`](#sec:parameterpoints): ([optional]{.smallcaps})     array of `object`s defining parameter points. These     [may]{.smallcaps} be used as starting points for minimizations or to     document best-fit-values or nominal truth values of datasets 

-   [`analyses`](#sec:analyses): ([optional]{.smallcaps}) array of     `object`s defining suggested analyses to be run on the models in     this file 

-   [`metadata`](#sec:metadata): [required]{.smallcaps} struct     containing meta information; HS$^3$ version number     ([required]{.smallcaps}), authors, paper references, package     versions, data/analysis descriptions ([optional]{.smallcaps}) 

-   [`misc`](#sec:misc): ([optional]{.smallcaps}) struct containing     miscellaneous information, e.g. optimizer settings, plotting colors,     etc. 
In the following each of these are described in more detail with respect to their own structure. 
