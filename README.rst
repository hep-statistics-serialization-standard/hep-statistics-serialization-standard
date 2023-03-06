*************************************
HS3 - HEP Statistics Serialization Standard
*************************************
Welcome to the High Energy Physics Statistics Serialization Standard.


**The project is in an early stage and currently resembles more of a working group and not yet a standard.**

**Everything, including naming, folder structure etc is under construction and open to discussion**


In short
========
The HEP Statistics Serialization Standard (HS3) defines standards of different statistical procedures and results used in High Energy Physics (HEP) in terms of human-and machine readable representations. Different versions are defined with specifications and semantics that are acknowledged by a committee. Corresponding implementations to check the validity of files are also provided, at a *best effort* basis.

More information can be found in the corresponding projects.

Why
====

There are two main motivation to have a code-independent representation of the likelihood and inference results.

- It allows to publish the likelihood; a long-term goal in High Energy Physics experiments.

- A framework- and language independent representation allows to use different frameworks interchangeably; at least for
reasonable complicated cases. It removes the dependency on code and reduces the need for maintenance of legacy projects.

