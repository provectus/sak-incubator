# Annotation
The S3 module is used to create s3 bucket on AWS.

## Used modules

- [iam-assumable-role](https://github.com/terraform-aws-modules/terraform-aws-iam/tree/v4.3.0/modules/iam-assumable-role)


## Feature

- IAM assumable role for accessing S3 bucket by other resources
- AWS cloudwatch group that collects logs from AWS Cloudtrail

## Example usage
```
module "s3" {
  depends_on                          = [ module.kubernetes]
  source                              = "./sak-incubator/storage/s3"
  s3_bucket_name                      = "${module.kubernetes.cluster_name}-main"
  cluster_name                        = module.kubernetes.cluster_name
  trusted_role_arns                   = [ module.kubernetes.this.cluster_iam_role_arn ]
  s3_cloudwatch_logging_enabled       = true
}
```
