# Hashicorp Vault
Module installing Hashicorp Vault helm chart in EKS cluster. Currently module support 2 kinds of storage type: S3 or FileStorage(EFS mounted as PVC)

## S3 storage type

In this storage type Vault will use S3 bucket. If `s3_create_bucket` set to true - there will be created  KMS key, S3 bucket with SSE. Also there will be created: IAM user, IAM user policy to access S3 bucket.

``` hcl
module "vault" {
  source           = "../hashicorp-vault/" # path of module folder
  cluster_name     = "swiss-army-kube"
  aws_region       = "eu-north-1"
  s3_storage       = true
  s3_create_bucket = true
  s3_bucket_name   = "sak-vault-test-bucket"
  s3_bucket_region = "eu-north-1"
}
```

## File storage type (EFS)
``` hcl
module "efs" {
  source                 = "../storage/efs/" # path of module folder
  cluster_name           = "swiss-army-kube"
  efs_name               = "sak-efs-folder"
  efs_folder_path        = "/vault"
  pvc_name               = "efs-pvc"
  chart_create_namespace = true
  chart_namespace        = "vault"
}

module "vault" {
  source                = "../hashicorp-vault/" # path of module folder
  cluster_name          = "swiss-army-kube"
  chart_namespace       = "vault"
  file_storage          = true
  file_storage_name     = "efs"
  file_storage_pvc_name = module.efs.pvc_name
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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| chart\_namespace | Kubernetes namespace name for Vault chart | `string` | `"default"` | no |
| cluster\_name | A name of the EKS cluster | `string` | n/a | yes |
| chart\_name | A name of the Vault chart | `string` | `"hashicorp-vault"` | no |
| chart\_create\_namespace | A option for creating Kubernetes namespace | `bool` | `false` | no |
| s3\_storage | A option to use Vault S3 storage type | `bool` | `false` | yes |
| s3\_create\_bucket | A option for creating S3 bucket | `bool` | `false` | yes |
| s3\_bucket\_name | A bucket name for Vault S3 storage type | `string` | `"swiss-army-kube-test-vault"` | yes |
| s3\_bucket\_region | AWS region name for S3 bucket | `string` | n/a | yes |
| file\_storage | A option to use Vault file storage type (EFS mounted as pvc) | `bool` | `false` | yes |
| file\_storage\_name | A volume name for Vault file storage type | `string` | `"efs"` | yes |
| file\_storage\_pvc_name | PVC name for Vault file storage type | `string` | `"efs-pvc"` | yes |
| tags | Tags to add to AWS resources | `map(string)` | `{}` | no |

## Outputs

Currently no output.



## Provisioning

After terraform apply you should initiate vault by next command:

If chart_name is `"hashicorp-vault"`
``` bash
kubectl exec -ti hashicorp-vault-0 -n vault -- vault operator init
```

There you will receive 5 keys for unsealing vault and root token for login.




### Known Issues

If you are using S3 storage type and want to destroy terraform objects - you should cleanup you bucket, because terrafrom will warn that bucket isn't empty.
