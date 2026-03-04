#import "/docs/hs3-defs.typ": sc
// Chapter 2.8: Metadata

== Metadata <sec:metadata>

The top-level component `metadata` contains meta-information related to the creation of the file. The component `hs3_version` stores the HS#super[3] version and is #sc[required] for now. Overview of the components:

- `hs3_version`: (#sc[required]) HS#super[3] version number as String for reference
- `packages`: (#sc[optional]) array of structs defining packages and their version number used in the creation of this file, depicted with the components `name` and `version` respectively
- `authors`: (#sc[optional]) array of authors, either individual persons, or collaborations
- `publications`: (#sc[optional]) array of document identifiers of publications associated with this file
- `description`: (#sc[optional]) short abstract/description for this file

#figure(caption: [Example: Metadata])[
```json
"metadata" : {
  "hs3_version" : "0.2.0",
  "packages" : [ { "name": "ROOT", "version": "6.28.02" } ],
  "authors": ["The ATLAS Collaboration", "The CMS Collaboration"],
  "publications": ["doiABCDEFG"]
}
```
]
