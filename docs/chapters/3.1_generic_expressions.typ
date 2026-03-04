#import "/docs/hs3-defs.typ": sc
// Chapter 3.1: Generic Expressions

== Generic Expressions <sec:generic_expression>

This section details the HS#super[3] _generic expression_ language.
Expressions can be use to specify generic functions and generic distributions.
The implementations that support generic expression #sc[must] support:

- Literal integer (format `1234`), boolean (format `TRUE` and `FALSE`) and floating point (format `123.4`, `1.234e2` and `1.234E2`) values.
- Literal values for $pi$ (`PI`) and Euler's number (`EULER`).
- The arithmetic operators addition (`x + y`), subtraction (`x - y`), multiplication (`x * y`), division (`x / y`) and exponentiation (`x^y`).
- The comparison operators approximately-equal (`x == y`), exactly-equal (`x === y`), not-approximately-equal (`x != y`), not-exactly-equal (`x !== y`), less-than (`x < y`), less-or-equal (`x <= y`), greater-than (`x > y`) and greater-or-equal (`x >= y`).
- The logical operators logical-inverse (`!a`), logical-and (`a && b`), logical-or (`a || b`).
- Round brackets to specify the order of operations.
- The ternary operator `condition ? result_if_true : result_if_false`
- The functions
  - `exp(x)`: Euler's number raised to the power of `x`
  - `log(x)`: Natural logarithm of `x`
  - `sqrt(x)`: The square root of `x`
  - `abs(x)`: The absolute value of `x`
  - `pow(x, y)`: `x` raised to the power of `y`
  - `min(x, y)`: minimum of `x` and `y`
  - `max(x, y)`: maximum of `x` and `y`
  - `sin(x)`: The sine of `x`
  - `cos(x)`: The cosine of `x`
  - `tan(x)`: The tangent of `x`
  - `asin(x)`: The inverse sin of `x`
  - `acos(x)`: The inverse cosine of `x`
  - `atan(x)`: The inverse tangent of `x`

Symbols not defined here refer to variables in the HS#super[3] model.
The operator precedence and associativity is according to the common conventions.
Spaces between operators and operands are optional. There must be no space between a function name and the function arguments, spaces between function arguments are optional (`f(a, b)` and `f(a,b)` are correct but `f (a, b)` is not allowed).

Division #sc[must] be treated as floating-point division (i.e. `2/3` should be equivalent to `2.0/3.0`).

The approximately-equal (`a == b`) and the not-approximately-equal operator (`a != b`), #sc[should] compare floating-point numbers to within a small multiple of the unit of least precision.

The behavior of any functions and operators not listed above is not defined, they are reserved for future versions of this standard. Implementations #sc[may] support additional functions and operators as experimental features, but their use is considered non-standard and results in non-portable and potentially non-forward-compatible HS#super[3] documents.
