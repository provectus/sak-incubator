# EFS
Module creates EFS in AWS for future usage inside PV/PVC. Also module install helm chart with EFS-CSI-DRIVER for Kubernetes.


## Example

``` hcl
module "efs" {
  source       = "../storage/efs/" # path of module folder
  cluster_name = "swiss-army-kube"
  argocd       = {}
  aws_region   = "eu-north-1"
  efs_name     = "sak-efs-folder"
}
```

## Requirements

```
terraform >= 0.15
 ```

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0 |
| helm | >= 1.0 |
| kubernetes | >= 1.11 |
| random | >= 3.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| aws_region | A AWS region name | `string` | n/a | yes |
| chart\_name | A name of csi-driver chart | `string` | `"aws-efs-csi-driver"` | no |
| chart\_version | A version of csi-driver chart | `string` | `"2.2.0"` | no |
| namespace | Kubernetes namespace name for PV/PVC | `string` | `"kube-system"` | no |
| conf | A set of parameters to pass to csi-driver chart | `map` | `{}` | no |
| cluster\_name | A name of the EKS cluster | `string` | n/a | yes |
| argocd | A set of values for enabling deployment through ArgoCD | `map(string)` | `{}` | no |
| efs\_name | A name of the EFS storage | `string` | n/a | yes |
| efs\_permissions | EFS directory permissions | `string` | `"700"` | no |
| mount\_options | A list of mount options | `list` | `[]` | yes |
| pvc\_name | A name of the Persistent Volume Claim | `string` | `"efs-pvc"` | no |
| pvc\_size | A size of the Persistent Volume Claim | `string` | `"5Gi"` | no |
| tags | Tags to add to AWS resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| pvc_name | A name of PVC |
