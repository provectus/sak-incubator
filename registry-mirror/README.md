# DockerHub registry mirror

## Required
* Internal nginx controller
* Cert-manager
* External dns

## Example
``` hcl
module "registry-mirror" {
  depends_on   = [module.argocd]
  source       = "github.com/provectus/sak-registry-mirror"
  cluster_name = module.kubernetes.cluster_name
  argocd       = module.argocd.state
  domains      = local.domain

  conf = {}
  tags = local.tags
}
```

## Providers

| Name | Version |
|------|---------|
| aws | n/a |
| helm | n/a |
| kubernetes | n/a |
| local | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| argocd | A set of values for enabling deployment through ArgoCD | `map(string)` | `{}` | no |
| chart\_version | A Helm Chart version | `string` | `"1.10.1"` | no |
| cluster\_name | A name of the Amazon EKS cluster | `string` | `null` | no |
| conf | A custom configuration for deployment | `map(string)` | `{}` | no |
| module\_depends\_on | A list of explicit dependencies | `list(any)` | `[]` | no |
| namespace | A name of the existing namespace | `string` | `"kube-system"` | no |
| namespace\_name | A name of namespace for creating | `string` | `"registry"` | no |
| tags | A tags for attaching to new created AWS resources | `map(string)` | `{}` | no |

## Outputs

No output.