---
bibliography: hs3.bib
---

# Amplitude models

This self-contained HS3 schema extends `RUB-EP1/amplitude-serialization/schema.json` at immutable revision `d0f0dff0eaa3025ed5aab2c7b85ccb36bd4b7524`. The schema `$id` identifies HS3 amplitude-callables extension version `1.0`, and `x-hs3-extension` records the exact baseline and extension version. A different baseline is compatible only after its unchanged models pass both schema and semantic validation against the extension; compatibility is not inferred from a newer version number.

The baseline root members—`distributions`, `domains`, `functions`, `misc`, and `parameter_points`—and its conventional `decay_description`, reference topology, chains, vertices, propagators, and intensity types retain their meanings. Conventional chains are not lowered to tensor expressions.

## Tensor-valued callable functions

A function with `type: tensor_callable` is a named callable whose evaluated result is a complex tensor. It is a peer of conventional chain components. Required members are `name`, `provider`, `function_id`, `convention_version`, `signature`, `parameters`, `result_axes`, and `assumptions`.

`provider` owns the stable `function_id`, convention versions, and provider-local conventions. `signature` contains the signed parent PDG identifier, ordered signed daughter PDG identifiers, and ordered particle roles; the first role describes the parent. Implementations shall select the unique registered callable signature from the signed parent and ordered daughter PDGs and shall verify the roles. Unknown or duplicate signatures, unequal signature-list lengths, unknown providers or functions, and unsupported convention versions are errors before evaluation. A newer version is compatible only when the provider explicitly declares compatibility.

Each parameter declares a name, vector kind (`complex_vector` or `real_vector`), ordered basis, and semantics envelope containing its owner and convention version. A HAMMER form-factor vector may additionally name its selected scheme or parametrization. Native form-factor-vector generation is delegated to the provider; this extension does not define a universal form-factor language.

Every result axis declares a semantic name, kind, ordered basis, optional particle role, and required convention. `status: fully_specified` permits composition according to the named convention. `status: provider_local` means the ordered basis is known while its physical frame or transport remains provider-owned. Provider-local axes shall not be composed across providers without an external compatibility declaration.

`provenance` is optional and has no mathematical effect. HAMMER `signature_index`, native integer labels, class spelling, and source revision may occur there. A `signature_index` hint may accelerate lookup or assert consistency, but absence does not change behavior and a hint inconsistent with semantic signature lookup is rejected.

HAMMER owns `hammer.*` identities in the `HAMMER` namespace. The current fixtures support `hammer-ligeti-2016npd-v1`. The HAMMER profile owns EFT operator normalization, flavor and scale conventions, native form-factor production, and unresolved spin/reference-spin frames.

## Tensor components and topology scope

`decay_description.tensor_components` contains peer amplitude components. Each unique component references one tensor callable and declares a `topology_scope`.

`boundary_particles` contains enclosing particle indices and `nodes` contains exact nodes from the existing nested `reference_topology`. `role_bindings` binds every ordered callable role to either a particle index or a named `intermediate_state`. `intermediate_states` associates a signed PDG and spin with an existing nested topology node; it does not introduce a second graph. The decomposed fixtures bind both the `B→D*μν` daughter and the `D*→Dπ` parent to `Dstar_12` at node `[1,2]`. `eliminated_internal_axes` records states already summed by a merged callable. Free backend node labels are not topology identities.

`chains` may be empty only when tensor components supply the amplitude. Conventional models need not contain these extension members.

## Local tensor composition and intensity

`tensor_composition` is not a general expression language. `components` lists one coherent amplitude and `contractions` contains explicit pairwise contractions. Every endpoint is `{component, axis}`. Contracted axes shall have identical ordered bases and compatible conventions and shall occur in at most one contraction.

The intensity lists scoped `{component, axis}` endpoints in `surviving_axes`, `summed_axes`, and pairs in `identified_axes`, plus a positive `initial_spin_average`. Identified axes select their compatible diagonal before summation. Every uncontracted result axis shall be classified exactly once. This extension adds no polarized density-matrix semantics.

## Antilinear vector maps

`antilinear_vector_map` defines $y=M\,\overline{x}$. Its input and output bind owner, convention, and ordered basis. Matrix rows follow the output basis and columns follow the input basis. Entries are real numbers or `[real, imaginary]` pairs. Semantic validation requires exactly `len(output.basis)` rows and `len(input.basis)` columns. The map is a coordinate transformation, not an EFT operator definition.

## Optional callable validation

`misc.callable_validation` is optional implementation-validation data, not function semantics. It qualifies a provider/function/version tuple at kinematic points. Every dense row-major complex-pair resource declares shape and SHA-256; SHA-256 validates resource transport. Implementations may run checks while qualifying a provider and need not run them during routine evaluation.

The declared portable comparison is `abs(a-b) <= absolute_scale + relative_tolerance*max(abs(a),abs(b))`, using positive serialized tolerances. A failure means that implementation has not qualified the provider contract; it does not redefine the function.

## Semantic validation

The reference validator runs before evaluation. Beyond JSON Schema it rejects duplicate names and semantic signatures; unresolved function, component, topology, subsystem, role, contraction, and intensity references; signature/topology mismatches; incompatible axes; malformed matrix dimensions; malformed resource shapes, value counts, encodings, or hashes; incomplete intensity classification; and unsupported provider/function/version tuples.

## Scope boundary and compact example

A truth amplitude model does not reconstruct a selected simulated sample, detector response, reconstruction, selection, corrections, or reconstructed-bin tensors. A compiled `hammer_template_dist` remains separately evaluable.

`amplitude-prototype/fixtures/bdmunu.compact-example.json` omits validation and all implementation provenance. It is evaluated through provider/function/version and the explicit signed PDG signature alone.
