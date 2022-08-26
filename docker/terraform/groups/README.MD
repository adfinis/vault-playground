# Vault Group Mapping Module

This TF module is used to map Vault groups across namespace hierarchies.

## Usage

Add or remove namespaces and group mappings in the `groups.yaml` file.

## Limitations

* Supplemental group mappings (non-admin groups) not yet implemented (only admin groups)
* #15: Module does not support mapping the same groups on mutliple namespaces, it only supports 1:1 mapping of AD groups to Vault namespaces.
