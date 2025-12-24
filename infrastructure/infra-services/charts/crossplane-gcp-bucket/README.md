# crossplane-gcp-bucket Helm chart

This chart installs a CompositeResourceDefinition (XRD) and a Composition for a simple GCS bucket XRD and composition targeting the Upbound GCP provider.

Install
-------

```bash
helm upgrade --install crossplane-gcp-bucket ./ --namespace crossplane-system --create-namespace
```

CRD migration note
------------------

If you previously installed an XRD for `gcsbuckets.storage.platform.example.org` the chart will not attempt to update it because some fields (like `spec.scope`) are immutable. If you need to migrate to the v2 XRD format and the existing XRD has a different `scope`, follow these steps carefully:

1. Ensure there are no existing composite resources (instances) of the XRD in any namespace (delete them or migrate them).
2. Delete the existing CompositeResourceDefinition: `kubectl delete compositeresourcedefinition gcsbuckets.storage.platform.example.org` (or use `kubectl delete xrd ...`).
3. Install this chart which will create the v2 XRD: `helm upgrade --install ...`.

If you prefer not to delete the existing XRD, the chart will skip creating the XRD and will only install the Composition; verify the existing XRD matches the desired API/fields.
