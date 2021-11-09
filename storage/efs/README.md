# EFS
Module creates EFS in AWS for future usage inside PV/PVC. Also module install helm chart with EFS-CSI-DRIVER for Kubernetes.


## Example

``` hcl
module "efs" {
  source       = "../storage/efs/" # path of module folder
  cluster_name = "swiss-army-kube"
  aws_region   = "eu-north-1"
  efs_name     = "sak-efs-folder"
  chart_namespace = "default"
  chart_create_namespace = false
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
| region | A AWS region name | `string` | n/a | yes |
| chart\_namespace | Kubernetes namespace name for PV/PVC | `string` | `"default"` | no |
| cluster\_name | A name of the EKS cluster | `string` | n/a | yes |
| efs\_name | A name of the EFS storage | `string` | n/a | yes |
| efs\_owner\_uid | A User ID for EFS configuration | `string` | `"1000"` | no |
| efs\_owner\_gid | A Group ID for EFS configuration | `string` | `"1000"` | no |
| efs\_folder\_path | A folder path inside EFS | `string` | `"/shared_folder"` | no |
| efs\_folder\_permissions | A folder permissions in EFS | `string` | `"775"` | no |
| pv\_name | A name of the Persistent Volume | `string` | `"efs-pv"` | no |
| pv\_size | A size of the Persistent Volume | `string` | `"5Gi"` | no |
| pvc\_name | A name of the Persistent Volume Claim | `string` | `"efs-pvc"` | no |
| pvc\_size | A size of the Persistent Volume Claim | `string` | `"5Gi"` | no |
| tags | Tags to add to AWS resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| aws_efs_file_system_id | A id of EFS object in AWS |
| aws_efs_access_point_id | A id of EFS access point in AWS |
