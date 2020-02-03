# HEP Statistics Standard
Overview of HEP statistics standard

## What is HSS
The HSS defines standards of statistics used in HEP in terms of human-and machine readable representations. It defines different versions with specifications and semantics that are acknowledged by a committee. Corresponding implementations to check the validity of files are also provided, at a _best effort_ basis.

More information can be found in the corresponding projects.

## Why

The main motivation is to have a code-independent representation of the likelihood and inference results.

This allows to publish the likelihood; a long-term goal in High Energy Physics experiments.

An framework- and language independent representation allows to use different frameworks interchangeably; at least for
reasonable complicated cases. It removes the dependency on code and reduces the need for maintenance of legacy projects.


## Projects

`HEP fit serialization <https://github.com/hep-statistics-standard/hep-fit-serialization>`_ provies a standard to store the essential parts of a fit, including models, data and the loss.

`HEP result serialization <https://github.com/hep-statistics-standard/hep-result-serialization>`_ provides a standard to store results from simple parameter uncertainty estimation to large toy studies.
