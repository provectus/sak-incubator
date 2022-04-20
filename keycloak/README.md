
It is a terraform module to deploy keycloak to EKS with ArgoCD. To integrate this module with our swiss-army-kube project, we add the module to the main terraform file:

## Example how add with module
```
module "keycloak" {
  source        = "git::https://github.com/provectus/sak-keycloak.git"
  cluster_name      = module.kubernetes.cluster_name
  argocd            = module.argocd.state
  domains           = local.domain
}
```





