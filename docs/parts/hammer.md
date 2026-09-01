---
bibliography: hs3.bib
---

HAMMER (Helicity Amplitude Module for Matrix Element Reweighting) is a
software library for the efficient reweighting of simulated
semileptonic heavy-flavour decays [@Bernlochner:2020uer]. Its primary
application is the study of processes such as $b\to c\ell\nu$, where
the predicted kinematic distributions depend on both short-distance
interactions, conventionally expressed through Wilson coefficients,
and hadronic form factors.

Experimental analyses typically rely on large simulated event samples
that include detector simulation, reconstruction, and event
selection. Regenerating these samples for every choice of Wilson
coefficients or form-factor parameters is generally
impractical. HAMMER instead computes, from the matrix elements
associated with each simulated event, a parameter-dependent weight
that allows an existing sample to be reinterpreted under different
physics hypotheses. This permits continuous variation of Wilson
coefficients and form-factor parameters without repeating the
expensive detector simulation.

For statistical inference, these event-level weights are commonly
accumulated into binned templates. HAMMER can compile the dependence
of such templates on the physics parameters into a set of response
tensors. Once this compilation has been performed, evaluating a
template at a new parameter point no longer requires access to the
original simulated events: the corresponding bin contents can be
obtained by contracting the stored response tensors with the
parameter-dependent HAMMER structures.

RooHammerModel [@GarciaPardinas:2020pgg] provides an interface between
HAMMER and RooFit/HistFactory. It exposes a HAMMER-reweighted
histogram as a parameter-dependent RooFit probability-density
function, allowing Wilson coefficients and form-factor parameters to
be varied directly in likelihood fits. In this setting, HAMMER
therefore forms part of the statistical model itself rather than
merely being a preprocessing step used to produce a fixed nominal
template.

### Scope of the HS$^3$ representation

The purpose of the serialization described below is to preserve this
parameter-dependent statistical model in HS$^3$. In particular, it
represents the **compiled HAMMER response** required to reconstruct
and evaluate the templates used by RooHammerModel. It is not intended
to serialize the original simulated events, to reproduce HAMMER's
amplitude calculations from first principles, or to define a portable
replacement for HAMMER itself.

The serialized representation consequently contains the effective
HAMMER configuration, the bindings between HS$^3$ parameters and
HAMMER Wilson-coefficient or form-factor parameters, the histogram
definitions, and the response tensors required to evaluate their
parameter dependence. Evaluation remains the responsibility of a
compatible HAMMER backend, which provides the semantics of
HAMMER-native process names, parametrizations, Wilson-coefficient
schemes, settings, and tensor labels.

This separation allows an HS$^3$ document to preserve the statistical
content of a RooHammerModel-based likelihood without embedding an
implementation-specific C++ object graph or an opaque HAMMER
archive. The resulting representation describes the mathematical
object that must be evaluated while retaining HAMMER as the
authoritative implementation of the underlying amplitude and
reweighting machinery.

### Mathematical definition

Let the observables be $x=(x_0,x_1,x_2)$ and let axis $a$ have strictly increasing visible-bin
edges

$$e_{a,0}<e_{a,1}<\cdots<e_{a,n_a}.$$

Visible bin $b=(b_0,b_1,b_2)$ is the half-open cell

$$B_b=[e_{0,b_0},e_{0,b_0+1})\times[e_{1,b_1},e_{1,b_1+1})
       \times[e_{2,b_2},e_{2,b_2+1}),$$

except that the final visible bin of each axis includes its upper edge. Its volume is

$$V_b=\prod_{a=0}^{2}(e_{a,b_a+1}-e_{a,b_a}).$$

At a parameter point $\theta$, the compatible HAMMER backend contracts the response selected by
`templates.without_errors` and returns one real bin weight $h_b(\theta)$ for every visible bin.
The primitive defines

$$q_b(\theta)=h_b(\theta)+\epsilon,$$

where $\epsilon$ is `evaluation.visible_bin_floor`. The normalization is

$$Z(\theta)=\sum_{b\text{ visible}}q_b(\theta).$$

For $x\in B_b$, the probability density is

$$p(x\mid\theta)=\frac{q_b(\theta)}{Z(\theta)V_b}.$$

For $x$ outside the visible histogram domain, evaluation returns
`evaluation.outside_domain_value`. This outside-domain compatibility value is not part of the
normalized distribution and an HS$^3$ domain used to normalize or sample this distribution
[must not]{.smallcaps} extend outside the visible histogram domain.

Every $q_b(\theta)$ and $Z(\theta)$ [must]{.smallcaps} be finite, every $q_b(\theta)$
[must]{.smallcaps} be non-negative, and $Z(\theta)$ [must]{.smallcaps} be strictly positive.
Violation is an evaluation error. `sum_squared_weights` and the template named by
`templates.with_errors` do not participate in $p(x\mid\theta)$; they are retained for uncertainty
propagation and diagnostics.

The division by $V_b$ makes the normalized bin contents probability masses and the returned
value a density. This is significant for unequal-width or non-unit-width bins.

### Distribution members

A HAMMER template distribution has the following members. Unless explicitly stated otherwise,
all are required and have no default.

- `name`: unique HS$^3$ object name.
- `type`: the string `hammer_template_dist`.
- `backend`: the string `HAMMER`.
- `x`, `y`, `z`: references to the three HS$^3$ observables, in histogram-axis order.
- `wilson_coefficients`: object with the required `process` member. Its value is the HAMMER
  Wilson-coefficient family updated by the Wilson-coefficient bindings.
- `form_factors`: object with required `process` and `group` members. They identify the HAMMER
  form-factor process and eigenvector group updated by the form-factor bindings.
- `parameter_bindings`: array relating HS$^3$ scalar parameters to HAMMER parameters.
- `templates`: selects the two histogram/scheme pairs used by RooHammerModel.
- `evaluation`: declares binning, normalization, floor, and error behaviour.
- `hammer`: the complete effective HAMMER configuration and compiled responses.
- `projection_provenance` (optional): non-evaluating provenance with `kind: compiled_mc_projection` and a nonempty `truth_model` reference to a separately serialized truth-amplitude model. It is absent when unset, round-trips exactly when set, does not participate in evaluation, and does not imply that the compiled response can be inverted.

Except for the explicitly defined `projection_provenance` link, information that does not affect evaluation belongs in the enclosing HS$^3$ document `misc` top-level component rather than in the distribution object.

### Parameter bindings

Each entry in `parameter_bindings` has exactly the members `parameter`, `target`, and `transform`.
`parameter` references an HS$^3$ scalar parameter.

A Wilson-coefficient target has the form

```json
{
  "kind": "wilson_coefficient",
  "process": "BtoCMuNu",
  "name": "S_qLlL"
}
```

Its transform is `real_part` or `imaginary_part`. For each bound complex coefficient there
[must]{.smallcaps} be exactly one binding of each kind. If their referenced HS$^3$ parameter
values are $r$ and $i$, the value supplied to HAMMER is $r+i\,i$. Every target `process`
[must]{.smallcaps} equal `wilson_coefficients.process`.

A form-factor target has the form

```json
{
  "kind": "form_factor_parameter",
  "process": "BtoD",
  "group": "CLNVar",
  "name": "delta_RhoSq"
}
```

Its transform is `identity`; the referenced real value is supplied unchanged. Its `process` and
`group` [must]{.smallcaps} equal the corresponding members of `form_factors`. A physical target
[must not]{.smallcaps} occur more than once. A parameter binding changes only its stated target.
All unbound HAMMER settings retain the effective values in `hammer.configuration.settings`.

### Template selection and evaluation

`templates` contains:

- `scheme`: a base name used to relate the two selections;
- `without_errors`: an object containing `histogram` and `scheme`;
- `with_errors`: an object containing `histogram` and `scheme`.

The two scheme values [must]{.smallcaps} respectively be
`templates.scheme + "_noErrors"` and `templates.scheme + "_withErrors"`. Each selected
histogram [must]{.smallcaps} have a definition and a response for the selected scheme and empty
specialization. The `without_errors` definition [must not]{.smallcaps} keep squared weights; the
`with_errors` definition [must]{.smallcaps} keep them. Their visible axes [must]{.smallcaps} be
identical.

`evaluation` has exactly these members and values:

```json
{
  "bin_order": "row_major_last_axis_fastest",
  "normalization": "visible_bin_sum",
  "visible_bin_floor": 1e-10,
  "outside_domain_value": 1e-12,
  "invalid_denominator": "error"
}
```

The two numeric values are model data, not defaults; they [must]{.smallcaps} be finite and
non-negative. `invalid_denominator: "error"` requires failure when HAMMER cannot form a finite
response because a denominator is zero or invalid. No clipping, event removal, or fallback is
permitted. Row-major order maps $b=(b_0,b_1,b_2)$ to

$$\operatorname{pos}(b)=((b_0n_1)+b_1)n_2+b_2.$$

### HAMMER model object

`hammer` contains exactly `configuration` and `histograms`. Together they are sufficient to
restore a compiled HAMMER response. Derived hashes and backend container choices are deliberately
absent.

#### Effective configuration

`configuration` contains exactly `settings`, `processes`, `pure_phase_space`, `schemes`, and
`specializations`.

`settings` is the complete effective setting store, including values equal to backend defaults.
Each entry contains `path`, `name`, `type`, optional `scope`, and, except for type `none`, `value`.
The allowed type tags and value forms are:

| `type` | `value` |
|---|---|
| `none` | absent |
| `bool` | Boolean |
| `int` | signed 32-bit integer |
| `double` | finite number |
| `string` | string |
| `complex` | `{ "re": number, "im": number }` |
| `string_list` | array of strings |
| `double_list` | array of finite numbers |
| `double_matrix` | rectangular array of finite-number arrays |

`scope` is one of `common`, `numerator`, or `denominator`; when absent its normative default is
`common`. The tuple `(scope, path, name)` [must]{.smallcaps} be unique. The explicit type tag is
semantic: readers [must not]{.smallcaps} infer it from the JSON literal.

`processes.included_decays` and `processes.forbidden_decays` are arrays of HAMMER decay patterns.
Each pattern is a non-empty ordered array of non-empty HAMMER vertex names. Their meaning is that
of the corresponding HAMMER included- and forbidden-decay declarations; array order is retained
but repeated patterns are permitted.

`pure_phase_space.numerator` and `pure_phase_space.denominator` are arrays of unique, non-empty
HAMMER vertex names assigned the respective phase-space role.

`schemes.input.parametrizations` maps HAMMER transition names to input parametrization names.
Each entry of `schemes.targets` has a unique non-empty `name` other than `Denominator` and a
`parametrizations` map of transitions to target parametrizations. Empty keys or values are
invalid. Every response `scheme` [must]{.smallcaps} name one of these target schemes.

`specializations.definitions` describes Wilson-coefficient specializations. Each entry contains
`wilson_coefficients`, `specialization`, an ordered non-empty `coordinates` array, and a numeric
`projector`. Names and coordinates are non-empty and unique in their relevant scope. The
projector has one axis for the native Wilson-coefficient family and one axis for the specialization;
its number of columns is the number of coordinates plus one, the additional column representing
the origin. `specializations.used_in_weights` is the unique list of specialization names applied
to weights. Every non-empty response specialization [must]{.smallcaps} be defined here.

#### Tensor values

A complex number is an object containing finite numeric `re` and `im` members. Standard JSON
non-finite spellings are not permitted.

A tensor value is one of the following tagged objects:

```json
{"kind":"scalar", "value":{"re":1.0,"im":0.0}}
```

```json
{
  "kind":"numeric_tensor",
  "axes":[{"label":"1002","extent":2}],
  "re":[1.0,0.2],
  "im":[0.0,-0.1]
}
```

```json
{
  "kind":"factorized_tensor",
  "factors":[
    {"axes":[{"label":"1002","extent":2}],"re":[1.0,0.2]}
  ],
  "terms":[
    {"factors":[{"factor":0,"conjugated":false}]}
  ]
}
```

An axis `label` is the full signed 64-bit HAMMER semantic index label, written as a canonical
decimal string. `extent` is a positive integer within the backend's supported index range. Axis
order is semantic. For extents $(d_0,\ldots,d_{k-1})$, dense component index

$$j=\sum_{a=0}^{k-1}i_a\prod_{c=a+1}^{k-1}d_c$$

corresponds to coordinates $(i_0,\ldots,i_{k-1})$. `re` has exactly $\prod_a d_a$ entries. `im`
is optional; if absent every imaginary component is zero, and if present it has the same length
as `re`.

A factorized tensor denotes the algebraic sum over `terms` of the outer product of the referenced
numeric factors. `factor` is a zero-based index into `factors`; `conjugated: true` complex
conjugates that factor before the product. Factors and terms are non-empty, references are in
range, and the resulting axis labels [must]{.smallcaps} be compatible with HAMMER contraction.
This factorization is mathematical structure, not amplitude provenance.

#### Histogram definitions and responses

`histograms` contains `definitions` and `responses`. Definition names are unique. A definition
contains:

- `name`;
- `axes`, in the same order as `x`, `y`, and `z` for selected templates;
- `underflow_overflow_bins`;
- `compresses_event_groups`;
- `keeps_sum_squared_weights`;
- `fixed_components`.

Each histogram axis contains a positive integer `extent` and strictly increasing finite `edges`.
Without flow bins it has `extent + 1` edges. With flow bins it has `extent - 1` edges, because the
first and last bins are unbounded. Selected distribution templates [must not]{.smallcaps} use flow
bins. A fixed component contains a signed decimal-string `label` and a rank-one numeric `tensor`
whose sole axis carries that label. Fixed labels are unique.

Each response contains `histogram`, `scheme`, `specialization`, `compressed`, and `groups`. The
first three form a unique key and reference a definition, target scheme, and optional
specialization. `compressed` records whether groups with equal response labels were merged; it
does not alter the mathematical sum.

A group contains `events`, `labels`, `bin_prototype`, and occupied `bins`. `events` is an array of
event identities, each represented by `{ "processes": [...] }`; process identifiers are unique
unsigned 64-bit canonical decimal strings. These identifiers preserve grouping and are not
portable names or tensor coordinates. `labels` is the ordered array of signed HAMMER tensor labels
for the response. `bin_prototype` contains the response tensor `name` and `axes`; it determines
the type of empty bins and [must]{.smallcaps} agree with every occupied bin.

Each occupied bin contains canonical unsigned decimal-string `position` and `event_count`, a
`sum_weights` tensor value, and `sum_squared_weights` exactly when the definition keeps squared
weights. Positions use the histogram's row-major order, are in range, unique within a group, and
sorted in canonical output. `event_count` is diagnostic bookkeeping and does not multiply the
stored response. Missing bins denote the additive zero tensor. HAMMER contracts fixed components,
group labels, and stored weight tensors according to its compiled-response semantics and sums all
groups to obtain $h_b(\theta)$.

### Example

The following non-normative structural excerpt omits most effective settings and tensor
coefficients only to keep the presentation short. It illustrates field relationships but is not
by itself a valid serialized model. A conforming example must populate the selected histogram
definitions and responses and must include the complete effective setting store.

```json
{
  "name": "hammerPdf",
  "type": "hammer_template_dist",
  "backend": "HAMMER",
  "x": "x",
  "y": "y",
  "z": "z",
  "wilson_coefficients": {"process": "BtoCMuNu"},
  "form_factors": {"process": "BtoD", "group": "CLNVar"},
  "parameter_bindings": [
    {
      "parameter": "reS_qLlL",
      "target": {
        "kind": "wilson_coefficient",
        "process": "BtoCMuNu",
        "name": "S_qLlL"
      },
      "transform": {"kind": "real_part"}
    },
    {
      "parameter": "imS_qLlL",
      "target": {
        "kind": "wilson_coefficient",
        "process": "BtoCMuNu",
        "name": "S_qLlL"
      },
      "transform": {"kind": "imaginary_part"}
    }
  ],
  "templates": {
    "scheme": "Scheme1",
    "without_errors": {"histogram": "histo_noErrors", "scheme": "Scheme1_noErrors"},
    "with_errors": {"histogram": "histo_Errors", "scheme": "Scheme1_withErrors"}
  },
  "evaluation": {
    "bin_order": "row_major_last_axis_fastest",
    "normalization": "visible_bin_sum",
    "visible_bin_floor": 1e-10,
    "outside_domain_value": 1e-12,
    "invalid_denominator": "error"
  },
  "hammer": {
    "configuration": {
      "settings": [
        {"path": "BtoCMuNu", "name": "SM", "scope": "numerator",
         "type": "complex", "value": {"re": 1.0, "im": 0.0}}
      ],
      "processes": {"included_decays": [["BDMuNu"]], "forbidden_decays": []},
      "pure_phase_space": {"numerator": [], "denominator": []},
      "schemes": {
        "input": {"parametrizations": {"BD": "ISGW2"}},
        "targets": [
          {"name": "Scheme1_noErrors", "parametrizations": {"BD": "CLNVar"}},
          {"name": "Scheme1_withErrors", "parametrizations": {"BD": "CLNVar"}}
        ]
      },
      "specializations": {"definitions": [], "used_in_weights": []}
    },
    "histograms": {
      "definitions": [],
      "responses": []
    }
  }
}
```

### Informative mapping to RooHammerModel

The outer members correspond to the normalized `RooHammerModel`; the nested `hammer` object maps
to `Hammer::Inference::ModelData`. `templates.without_errors` supplies the nominal cached
histogram, while `templates.with_errors` supports retrieval of a histogram with propagated
sum-of-squared-weight information.
