# Meta AWS Application
This module creates the deployment on a Kubernetes cluster using Helm (as an option via ArgoCD) for the abstract application with IRSA integration.

## Usage:
``` hcl
module "aws_lb_controller" {
  source = "github.com/provectus/sak-incubator//meta-aws-application"

  chart_version = "1.2.7"
  repository    = "https://aws.github.io/eks-charts"
  name          = "aws-load-balancer-controller"
  chart         = "aws-load-balancer-controller"

  iam_permissions = [
    {
      "Effect" = "Allow",
      "Action" = [
        "iam:CreateServiceLinkedRole",
        ...
      ],
      "Resource" = "*"
    },
    ...
  ]

  cluster_name = var.cluster_name
  values = {
    clusterName = var.cluster_name
    vpcId       = var.vpc_id
    region      = data.aws_region.current.name
    defaultTags = var.tags
  }
  argocd = var.argocd
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:-----:|
| argocd | A set of values for enabling deployment through ArgoCD | `map(string)` | `{}` | no |
| chart | A Helm Chart name | `string` | n/a | yes |
| chart\_version | Version of Helm Chart | `string` | `"0.1.0"` | no |
| cluster\_name | A name of the Amazon EKS cluster | `string` | n/a | yes |
| destination\_server | A destination server for ArgoCD application | `string` | `"https://kubernetes.default.svc"` | no |
| iam\_permissions | A list of IAM permissions required for application launch | `any` | `[]` | no |
| irsa\_annotation\_field | A filed name for specifying IRSA annotation | `string` | `"rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"` | no |
| name | A name of the application | `string` | n/a | yes |
| namespace | A name of the existing namespace | `string` | `"default"` | no |
| namespace\_name | A name of namespace for creating | `string` | `"application"` | no |
| repository | A repository of Helm Chart | `string` | n/a | yes |
| service\_account\_name | A name of the service account, in case of using custom SA name not matching with application name | `string` | `""` | no |
| tags | A tags for attaching to new created AWS resources | `map(string)` | `{}` | no |
| values | A values for Helm Chart | `map` | `{}` | no |