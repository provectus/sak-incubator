# sak-sentry

Terraform module to deploy Sentry
https://sentry.io/

## Example
Simple use-case
``` hcl
module "sentry" {
  depends_on = [module.argocd]
  source       = "../../sak-sentry"
  cluster_name = module.kubernetes.cluster_name
  argocd       = module.argocd.state
  conf         = {}
  tags         = local.tags
}
```
