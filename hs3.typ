// HS3 - HEP Statistics Serialization Standard
// Central document file

#set document(
  title: [HS#super[3] v0.2.9],
  author: (
    "Carsten Burgard",
    "Tomas Dado",
    "Jonas Eschle",
    "Matthew Feickert",
    "Cornelius Grunwald",
    "Alexander Held",
    "Jerry Ling",
    "Robin Pelkner",
    "Jonas Rembser",
    "Oliver Schulz",
  ),
  date: datetime(year: 2025, month: 9, day: 1),
)

#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
  numbering: "1",
)

#set text(font: "New Computer Modern", size: 11pt)
#set par(justify: true)
#set heading(numbering: "1.1.1.1")
#set math.equation(numbering: "(1)")

// Shared definitions
#import "docs/hs3-defs.typ": sc

// Title page
#align(center)[
  #v(3cm)
  #text(size: 24pt, weight: "bold")[HS#super[3] v0.2.9]
  #v(1cm)
  #text(size: 12pt)[
    Carsten Burgard, Tomas Dado, Jonas Eschle, Matthew Feickert, \
    Cornelius Grunwald, Alexander Held, Jerry Ling, \
    Robin Pelkner, Jonas Rembser, Oliver Schulz
  ]
  #v(0.5cm)
  #text(size: 11pt)[2025-09-01]
  #v(2cm)
]

// About section (unnumbered)
#heading(level: 1, numbering: none)[About this document]

#block(inset: (left: 1em))[
  #image("docs/images/cc0.png", height: 1em) To the extent possible under law, the authors have waived all
  copyright and related or neighboring rights to this document. For details,
  please refer to the _Creative Commons_ `CC0` license @cc0.
  This work is published from: CERN, Geneva.
]

// Include chapters
#include "docs/chapters/1_introduction.typ"

#include "docs/chapters/2_toplevels.typ"

#include "docs/chapters/2.1_distributions.typ"

#include "docs/chapters/2.1.1_fundamental_distributions.typ"

#include "docs/chapters/2.1.2_composite_distributions.typ"

#include "docs/chapters/2.2_functions.typ"

#include "docs/chapters/2.3_data.typ"

#include "docs/chapters/2.4_likelihoods.typ"

#include "docs/chapters/2.5_domains.typ"

#include "docs/chapters/2.6_parameter_points.typ"

#include "docs/chapters/2.7_analyses.typ"

#include "docs/chapters/2.8_metadata.typ"

#include "docs/chapters/2.9_misc.typ"

#include "docs/chapters/3_supplementary.typ"

#include "docs/chapters/3.1_generic_expressions.typ"

// Bibliography
#bibliography("docs/hs3.bib", style: "ieee")
