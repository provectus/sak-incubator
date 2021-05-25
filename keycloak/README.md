It is a etrraform module to deploy keycloak to EKS with ArgoCD.
to integrate this module with our swiss-army-kube project, we add the module in main terraform file:


module "keycloak
  depends_on   = [module.argocd]
  source       = "github.com/jamal68/sak-incubator/keycloak"
  cluster_name = module.kubernetes.cluster_name
  argocd       = module.argocd.state
  domains      = local.domain

