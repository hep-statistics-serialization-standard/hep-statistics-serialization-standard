---
bibliography: ./hs3.bib
---


HistFactory [@hf] is a language to describe statistical models consisting only of "histograms" (which is used interchangeably with "step-functions" in this context). Each HistFactory distribution describes one "channel" or "region" of a binned measurement, containing a stack of "samples", i. e.&nbsp;binned distributions sharing the same binning (step-functions describing the signal or background of a measurement). Such a HistFactory model is shown in Figure [1](#fig:hf-example){reference-type="ref" reference="fig:hf-example"} (originally from  [@atlashzz]). Each of the contributions may be subject to `modifiers`. 

![A binned statistical model describing a High Energy Physics measurement, in this case of the $H\rightarrow 4l$ process by the ATLAS collaboration. Three different sample (blue, red, violet) are considered.](/images/hf-example.png){#fig:hf-example width=".6\%"} 

The prediction for a binned region is given as 

$$
\begin{aligned} \lambda(x)=\sum_{s\in\text{samples}} \left[ \left( d_s(x) + \sum_{\delta\in M_{\delta}} \delta(x,\theta_\delta) \right) \prod_{\kappa\in M_\kappa} \kappa(x,\theta_\kappa)   \right] \end{aligned} 
$$



Here $d_s(x)$ is the prediction associated with the sample $s$, a step function 



$$
\begin{aligned} d_s(x) = \chi^{y_s}_{b}(x) \end{aligned} 
$$



In this section, $\chi^{y_s}_{b}(x)$ denotes a generic step function in the binning $b$ such that $\chi_{b}(x) = y_{s,i}$, some constant, if $x\in[b_i,b_{i+1})$. The $y_{s,i}$ in this case are the bin contents (yields) of the histograms. 
The $M_\kappa$ are the multiplicative modifiers, the $M_\delta$ are the additive modifiers. Each of the modifiers is either multiplicative ($\kappa$) or additive ($\delta$). All samples and modifiers share the same binning $b$. 
The modifiers depend on a set of nuisance parameters $\theta$, where each modifier can only depend on one $\theta_i$, but the $\theta_i$ can take the form of vectors and the same $\theta_i$ can be shared by several modifiers. By convention, these are denoted $\alpha$ if they affect all bins in a correlated way, and $\gamma$ if they affect only one bin at a time. The types of modifiers are 

-   A *uncorrelated shape systematic* or `shapefactor` modifier is a     multiplicative modifier that scales each single bin by the value of     some independent parameter $\gamma$. Here, $\theta_i=\vec{\gamma}$,     where the length of $\vec{\gamma}$ is equal to the number of bins in     this region. *This type of modifier is sometimes called `shapesys`,     with some nuance in the meaning. However, both are synonymous in the     context of this standard.* 
-   A *correlated shape systematic* or `histosys` modifier is an     additive modifier that adds or subtracts a constant step function     $\chi^f$, scaled with a single factor $\alpha$. The modifier     contains a `data` section, which contains the subsections     $\texttt{hi}$ and $\texttt{lo}$ that help to define the step     function $\chi^f$. They contain `contents`, which define the     bin-wise additions or subtractions for $\alpha=1$. The functional form of $\chi^f$ for intermediate and outlying $\alpha$ is set by the `interpolation` component, described below. Here,     $\theta_i=\alpha$. 
-   A *normalization systematic* or `normsys` modifier is a     multiplicative modifier that scales the entire sample with the same     constant factor $f$ that is a function of $\alpha$. The modifier     contains a `data` section, which contains the values $\texttt{hi}$     and $\texttt{lo}$ that help to define $f$. There are different     functional forms that can be chosen for $f$. However, by convention     $f(\alpha=0)=1$, $f(\alpha=+1)=$"`hi`" and     $f(\alpha=-1)=$"`lo`". The functional form of $f$ for intermediate and outlying $\alpha$ is set by the `interpolation` component, described below. In this case, $\theta_i=\alpha$. 
-   A *normalization factor* or `normfactor` modifier is a     multiplicative modifier that scales the entire sample in this region     with the value of the parameter $\mu$ itself. In this case,     $\theta_i=\mu$. 
-   The `staterror` modifier is a shorthand for encoding uncorrelated     statistical uncertainties on the values of the step-functions, using     a variant[^1] of the Barlow-Beeston Method [@barlowbeeston]. Here,     the relative uncertainty on the sum of all samples in this region     containing the `staterror` modifier is computed bin-by-bin. Then, a     constrained *uncorrelated shape systematic* (`shapesys`) is created,     encoding these relative uncertainties in the corresponding `Poisson`     (or `Gaussian`) constraint term. 

The different modifies and their descriptions are also summarized in the following table: 

| **Type of Modifier**         | **Description**               | **Definition**                               | **Free Parameters**           | **Number of Free Parameters** |
|------------------------------|-------------------------------|----------------------------------------------|-------------------------------|--------------------------------|
| `histosys`                   | Correlated Shape systematic   | $\delta(x,\alpha) = \alpha * \chi_b^f$       | $\alpha$                      | 1                              |
| `normsys`                    | Normalization systematic      | $\kappa(x,\alpha) = f(\alpha)$               | $\alpha$                      | 1                              |
| `normfactor`                 | Normalization factor          | $\kappa(x,\mu) = \mu$                        | $\mu$                         | 1                              |
| `shapefactor`, `staterror`   | Shape factor                  | $\kappa(x,\vec{\gamma}) = \chi_b^{\gamma}$   | $\gamma_0$, ..., $\gamma_n$   | #bins                          |


The `staterror` modifier is a special subtype of `shapefactor`, where the mean of the constraint is given as the sum of the predictions of all the samples carrying a `staterror` modifier in this bin.  

The way modifiers affect the yield in the corresponding bin is subject to an interpolation function. The `histosys` and `normsys` modifiers thus allow for an additional component `interpolation`, a struct with the components 

-   `type`: how the response combines with the sample prediction, `add` or `mult`, for additive or multiplicative, respectively, 
-   `in`: the interpolating function used inside the bounds, $|\theta|<1$, 
-   `out`: the extrapolating function used outside the bounds, $|\theta|\geq1$, if `null` the same function as for interpolation is used.

The response is a scalar function $y(\theta;y_-,y_0,y_+)$ with anchors $y(0)=y_0$ and $y(\pm1)=y_\pm$, where $y_0$ and $y_\pm$ correspond to the nominal and `hi`/`lo`, respectively. 

For the two option for `type="mult"` $y(\theta, y_0, y_+, y_-)$ combines to:

$$  
y(\theta) = y_0 \cdot \prod_i y(\theta_i, y_0, y_+, y_-),
$$

while for `type="add"` the combinations follows as:

$$
y(\theta) = y_0 + \sum_i y(\theta_i, y_0, y_+, y_-).
$$

The following functions are allowed for `in` and `out`:  

- `poly1`: linear function
- `poly2`: parabolic function
- `poly6`: degree-6 polynomial
- `exp`: exponential function

The choice of functions for `in` and `out`, together with the anchor conditions ($y(0) = y_0$, $y(\pm1) = y_\pm$) and, where required, matching of first and second derivatives at the boundary ($\left.\frac{\mathrm{d}y}{\mathrm{d}\theta}\right|_{\theta=\pm 1}$ and $\left.\frac{\mathrm{d}^2y}{\mathrm{d}\theta}\right|_{\theta=\pm 1}$), fixes all free parameters of the chosen functions except for $\theta$ itself.


The following combinations are often used and showcase the :

- additive, piecewise linear: 
    - `{"type":"add", "in":"poly1", "out":null}`
    - with $y_1(\theta, y_0, y_+, y_-) = \left\{ \begin{array}{ll} \theta\cdot(y_+ - y_0) &  \theta\geq0 \\ \theta\cdot(y_0-y_-) &  \theta<0\end{array}\right.$

- multiplicative, piecewise exponential: 
    - `{"type":"mult", "in":"exp", "out":null}`
    - with $y_2(\theta, y_0, y_+, y_-) = \left\{ \begin{array}{ll} (y_+/y_0)^\theta &  \theta\geq0 \\ (y_-/y_0)^{-\theta} &  \theta<0 \end{array}\right.$

- additive, quadratic interpolation and linear extrapolation 
    - `{"type":"add", "in":"poly2", "out":"poly1"}`
    - with $y_3(\theta, y_0, y_+, y_-) = \left\{\begin{array}{ll}(2s+d)\cdot(\theta - 1) + y_+ - y_0 &  \theta > 1 \\ s\cdot\theta^2 +d\cdot\theta & |\theta|\leq 1 \\ -(2s+d)\cdot(\theta + 1) + y_- - y_0& \theta < -1\end{array}\right.$,  
  where $s=\tfrac12(y_+ + y_-) - y_0$ and $d=\tfrac12 (y_+ - y_-)$
- additive, polynomial (6th degree) interpolation and linear extrapolation 
    - `{type:"add", in:"poly6", out:"poly1"}`
    - with $y_4(\theta, y_0, y_+, y_-) = \left\{\begin{array}{ll} \theta\cdot(y_+ - y_0) & \theta \geq 1 \\ \theta\cdot(S+\theta \cdot A (15+\theta^2\cdot(3\theta^2 -10))) & |\theta| < 1 \\ \theta\cdot(y_0 - y_-) & \theta \leq -1 \end{array}\right.$,  
  where $S=\tfrac12(y_+ - y_-)$ and $A=\tfrac{1}{6}(y_+ + y_- -2y_0)$
- multiplicative, polynomial (6th degree) interpolation and exponential extrapolation 
    - `{type:"mult", in:"poly6", out:"exp"}`
    - with $y_5(\theta, y_0, y_+, y_-) = \left\{\begin{array}{ll} (y_+/y_0)^\theta &  \theta\geq 1 \\ 1+\theta\cdot(a+\theta\cdot(b+\theta\cdot(c+\theta\cdot(d+\theta\cdot(e+\theta\cdot f)))))& |\theta|<1\\ (y_-/y_0)^{-\theta} &  \theta\leq-1\end{array}\right.$,  
  where: $\begin{array}{l}a=\tfrac18(15A_0-7S_1+A_2) \\ b=\tfrac18(-24+24S_0-9A_1+S_2) \\ c=\tfrac14(-5A_0+5S_1-A_2) \\ d=\tfrac14(12-12S_0+7A_1-S_2) \\ e = \tfrac18 (3A_0 -3S_1+A_2) \\ f=\tfrac18 (-8+8S_0-5A_1+S_2)\end{array}$, with: $\begin{array}{l}S_0=\tfrac12(y_+ + y_-) \\ A_0=\tfrac12(y_+ - y_-) \\ S_1=\tfrac12(y_+\log{y_+} + y_-\log{y_-}) \\ A_1=\tfrac12(y_+\log{y_+} - y_-\log{y_-}) \\ S_2=\tfrac12(y_+\log^2{y_+} + y_-\log^2{y_-}) \\ A_2=\tfrac12(y_+\log^2{y_+} - y_-\log^2{y_-})\end{array}$ 
- multiplicative, polynomial (6th degree) interpolation and linear extrapolation 
    - `{type:"mult", in:"poly6", out:"poly1"}`
    - with $y_6(\theta, y_0, y_+, y_-) = 1 + y_4(\theta, y_0, y_+, y_-)$

Modifiers can be constrained. This is indicated by the component `constraint`, which identifies the type of the constraint term. In essence, the likelihood picks up a penalty term for changing the corresponding parameter too far away from its nominal value. The nominal value is, by convention, defined by the type of constraint, and is 0 for all modifiers of type `sys` (`histosys`, `normsys`) and is 1 for all modifiers of type `factor` (`normfactor`, `shapefactor`). The strength of the constraint is always such that the standard deviation of constraint distribution is $1$. 

The supported constraint distributions, also called constraint types, are `Gauss` for a gaussian with unit width (a gaussian distribution with a variance of $1$), `Poisson` for a unit Poissonian (e.g. a continous Poissonian with a central value 1), or `LogNormal` for a unit LogNormal,. If a constraint is given, a corresponding distribution will be considered in addition to the `aux_likelihood` section of the likelihood, constraining the parameter to its nominal value. 

An exception to this is provided by the `staterror` modifier as described above, and the `shapesys` for which a Poissonian constraint is defined with the central values defined as the squares of the values defined in `vals`. 

The components of a HistFactory distribution are: 
    
-   `name`: custom unique string 
-   `type`: `histfactory_dist` 
-   `axes`: array of structs representing the axes. If given each struct     needs to have the component `name`. Further,     ([optional]{.smallcaps}) components are `max`, `min` and `nbins`,     or, alternatively, `edges`. The definition of the axes follows the     format for binned data (see Section 
    [Binned Data](#sec:binned-data){reference-type="ref"     reference="sec:binned-data"}). 
-   `default_interpolation`: [optional]{.smallcaps} struct defining the default interpolation behaviour, for modifiers that do not specify it on their own. It has the components `type`, `in` and `out`, as described above.
-   `samples`: array of structs containing the samples of this channel.     For details see below. 
Struct of one sample:  
    -   `name`: ([optional]{.smallcaps}) custom string, unique within this     function 
    -   `data`: struct containing the components `contents` and `errors`,     depicting the data contents and their errors. Both components are     arrays of the same length. 
    -   `modifiers`: array of structs with each struct containing the modifiers for this sample.
    Struct of one modifier:
        -  `type`: type of the modifier
        -  `parameter` or `parameters`: defining a string or an array of strings, respectively. Relating to the name or names of parameters controlling this modifier. Two modifiers are correlated exactly if they share the same parameters as indicated by `parameter` or `parameters`. In such a case, it is mandatory that they share the same constraint term. If this is not the case, the behavior is undefined. 
        -  `data`: [optional]{.smallcaps} relevant data for modifier. Its format depends on `type`, which is described above.
        -  `constraint`: [optional]{.smallcaps} definition of how the modifier is constrained. Its format depends on `type`, which is described above.
        -  `interpolation`: [optional]{.smallcaps} struct defining how the effect of the modifier is calculated within and outside of the boundaries $\theta=\pm 1$. It has the components `type`, `in` and `out` as described above. If this is ommited here for at least one modifier the top-level component `default_interpolation` becomes [required]{.smallcaps}.

```json title="HistFactory"
{
  "name": "myAnalysisChannel",
  "type": "histfactory_dist",
  "axes": [ 
	{ "max": 1.0, "min": 0.0, "name": "myRegion", "nbins": 2 } 
  ],
  "name":"myChannel1",
  "default_interpolation": { "type": "mult", "in": "poly6", "out": "exp" },
  "samples": [
    { 
      "name": "mySignal",
      "data": { "contents": [ 0.5, 0.7 ], "errors": [ 0.1, 0.1 ] },
      "modifiers": [
        { "parameter": "Lumi", "type": "normfactor" },
        { "parameter": "mu_signal_strength", "type": "normfactor" },
        { "constraint": "Gauss", "data": { "hi": 1.1, "lo": 0.9 }, 
          "parameter": "my_normalization_systematic_1", 
          "type": "normsys" },
        { "constraint": "Poisson", "type": "staterror", 
          "parameters": ["gamma_stat_1","gamma_stat_2"]},
        { "constraint": "Gauss", "type": "histosys", 
          "data": { 
            "hi": { "contents": [ -2.5, -3.1 ] }, 
            "lo": { "contents": [ 2.2, 3.7 ] } 
           }, 
           "interpolation": { "type": "add", "in": "poly6", "out": "poly1" },
           "parameter": "my_correlated_shape_systematic_1" },
        { "constraint": "Poisson", "data": { "vals": [ 0.0, 1.2 ] }, 
          "parameter": "my_uncorrelated_shape_systematic_2", 
          "type": "shapesys" }
      ]
    },
    { 
      "name": "myBackground",
      ... 
   }
  ]
} 
```


[^1]: The variation consists of summarizing all contributions in the     stack to a single contribution as far as treatment of the     statistical uncertainties is concerned. 
