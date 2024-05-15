# HS3 - HEP Statistics Serialization
Standard
Welcome to the High Energy Physics Statistics Serialization Standard.

**The project is in an early stage and currently resembles more of a
working group and not yet a standard.**

**Everything, including naming, folder structure etc is under
construction and open to discussion**


# In short

The HEP Statistics Serialization Standard (HS3) defines standards of
different statistical procedures and results used in High Energy Physics
(HEP) in terms of human-and machine readable representations. Different
versions are defined with specifications and semantics that are
acknowledged by a committee. 

View the current draft of the HS3 standard here: https://www.overleaf.com/read/ywzfwjhwvqrv

Corresponding implementations to check the
validity of files are also provided, at a *best effort* basis.
More information can be found in the corresponding projects.

# Why

There are two main motivation to have a code-independent representation
of the likelihood and inference results.

-   It allows to publish the likelihood; a long-term goal in High Energy
    Physics experiments.

- A framework- and language independent representation allows to use
different frameworks interchangeably; at least for reasonable
complicated cases. It removes the dependency on code and reduces the
need for maintenance of legacy projects.

# Goal

HS3 standardizes the machine- and human-readable serialization of all
components involved in model fitting as used in High Energy Physics.
This includes the definition of the model, the data as well as the loss
function. The aim is to provide on one hand a language and framework
agnostic, machine-reabable and on the other hand a human-readable,
publishable and preservable representation. This would allow to
interchange the fitting framework and decouple the reproducibility from
the frameworks lifetime.

The focus of this project is not on the long-term storage of large data,
which may be needed for an actual implementation, but rather to define a
common serialization format.

TODO: more description

# Standard versions

Until 1.x, the standard is considered unstable and may introduce
backwards incompatible changes.

After that, backwords compatibility is guaranteed to be maintained
inside the major releases (1.x, 2.x) and should be kept, if possible,
also between the major releases, but is not guaranteed in favor of a
cleaner standard.

# Participation

In order to submit ideas, proposals and examples, you can either start a
discussion using issues or add the document(s), if you have some, in the
proposals (draft or pending) folder and create a PR to discussion them.

If you are interest to become part of the core committee, please open an
issue. Anyone is allowed to join.

# Contact

To stay updated, you can sign up for the e-group:
<hep-statistics-serialization-standard@cern.ch>

# Involved projects

## zfit

A model fitting library in pure Python. It\'s focus is on
customizability and strong model building.

[zfit on Github](https://github.com/zfit/zfit)

## pyhf

Pure-Python implementation of statistical model for multi-bin
histogram-based analysis and its interval estimation; HistFactory in
Python.

[pyhf on Github](https://github.com/scikit-hep/pyhf)

## RooFit

The Toolkit for Data Modeling with ROOT (RooFit) is a package that
allows for modeling probability distributions in a compact and abstract
way.

[RooFit](https://root.cern.ch/roofit)

## BAT.jl

The Bayesian Analysis Toolkit in Julia.

[BAT.jl on Github](https://github.com/bat/BAT.jl)

# Users

## ATLAS

The ATLAS Collaboration has published measurements in this format:
 - Measurement of the $t\bar{t}$ cross section and its ratio to the $Z$ production cross section using $pp$  collisions at $\sqrt{s}=13.6$ TeV with the ATLAS detector ([HEPdata](https://www.hepdata.net/record/ins2689657?version=1))

# Committee

The comittee is responsible for the acceptance and denial of new
proposals and has to approve a new version of the standard.
