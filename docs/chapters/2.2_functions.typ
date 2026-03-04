#import "/docs/hs3-defs.typ": sc
// Chapter 2.2: Functions

== Functions <sec:functions>

The top-level component `functions` describes an array of mathematical functions in struct format to be used as helper objects. Similar to distributions each entry is #sc[required] to have the components `type` and `name`. Other components are dependent on the kind of functions. The field `name` is #sc[required] and may be any custom unique string. Functions in general have the following components:

- `name`: custom unique string
- `type`: string that determines the kind of function, e.g. `sum`
- `...`: each function has individual parameter keys for the various individual parameters. For example, functions of type `sum` have the parameter key `summands`. In general, these keys can describe strings as references to other objects or numbers. Depending on the parameter and the type of function, they appear either in single item or array format.

#figure(caption: [Example: Functions])[
```json
"functions": [
  {
    "name" : "sum1",
    "type" : "sum",
    "summands" : [1.8, 4, "param_xy"]
  },
  ...
]
```
]

In the following the implemented functions are described in detail.

=== Product

A product of values or functions $a_i$.

$ "Prod" = product_i^n a_i $

- `name`: custom unique string
- `type`: `product`
- `factors`: array of names of the elements of the product or numbers.

=== Sum

A sum of values or functions $a_i$.

$ "Sum" = sum_i^n a_i $

- `name`: custom unique string
- `type`: `sum`
- `summands`: array of names of the elements of the sum or numbers.

=== Generic Function

_Note: Users should prefer the specific functions defined in this standard over generic functions where possible, as implementations of these will typically be more optimized. Generic functions should only be used if no equivalent specific distribution is defined._

A generic function is defined by an expression. The expression must be a valid HS#super[3]-expression string (see @sec:generic_expression).

- `name`: custom unique string
- `type`: `generic_function`
- `expression`: a string with a generic mathematical expression. Simple mathematical syntax common to programming languages should be used here, such as `x-2*y+z`. For any non-elementary operations, the behavior is undefined.
