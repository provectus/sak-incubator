
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

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_helm"></a> [helm](#provider\_helm) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | n/a |
| <a name="provider_local"></a> [local](#provider\_local) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [helm_release.keycloak](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [kubernetes_namespace.this](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace) | resource |
| [local_file.this](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_argocd"></a> [argocd](#input\_argocd) | A set of values for enabling deployment through ArgoCD | `map(string)` | `{}` | no |
| <a name="input_chart_version"></a> [chart\_version](#input\_chart\_version) | A Helm Chart version | `string` | `"3.0.3"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | A name of the Amazon EKS cluster | `string` | `null` | no |
| <a name="input_conf"></a> [conf](#input\_conf) | A custom configuration for deployment | `map(string)` | `{}` | no |
| <a name="input_domains"></a> [domains](#input\_domains) | A list of domains to use for ingresses | `list(string)` | <pre>[<br>  "local"<br>]</pre> | no |
| <a name="input_module_depends_on"></a> [module\_depends\_on](#input\_module\_depends\_on) | A list of explicit dependencies | `list(any)` | `[]` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | A name of the existing namespace | `string` | `""` | no |
| <a name="input_namespace_name"></a> [namespace\_name](#input\_namespace\_name) | A name of namespace for creating | `string` | `"oauth"` | no |

## Outputs

No outputs.
It is a etrraform module to deploy keycloak to EKS with ArgoCD.
to integrate this module with our swiss-army-kube project, we add the module in main terraform file:

   
  
To retrive keyclock password:
aws --region <your-region> ssm get-parameter  --with-decryption --name /<your-cluster-name>/keyclock/password | jq -r '.Parameter.Value' 

