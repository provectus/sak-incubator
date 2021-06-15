data "aws_region" "current" {}

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}
  
resource "kubernetes_namespace" "this" {
  depends_on = [
    var.module_depends_on
  ]
  count = var.namespace == "" ? 1 - local.argocd_enabled : 0
  metadata {
    name = var.namespace_name
  }
}

resource "helm_release" "keyclok" {
  count = 1 - local.argocd_enabled
  depends_on = [
    var.module_depends_on
  ]
  
  name          = local.name
  repository    = local.repository
  chart         = local.chart
  version       = var.chart_version
  namespace     = local.namespace
  recreate_pods = true
  timeout       = 1200
  
    dynamic "set" {
    for_each = local.conf
  
      content {
      name  = set.key
      value = set.value
    }
}

module "iam_assumable_role_admin" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  #  version                       = "~> v3.6.0"
  create_role                   = true
  role_name                     = "${var.cluster_name}_keycloak"
  provider_url                  = replace(data.aws_eks_cluster.this.identity.0.oidc.0.issuer, "https://", "")
  role_policy_arns              = [aws_iam_policy.this.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.namespace}:keyclok"]
  tags                          = var.tags
}

resource "aws_iam_policy" "this" {
  name_prefix = "keyclok"
  description = "EKS keyclok policy for cluster ${data.aws_eks_cluster.this.id}"
  policy      = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "this" {
  statement {
    sid    = "keyclock"
    effect = "Allow"

    actions = [
      "kms:Decrypt"
    ]

    resources = [aws_kms_key.this.arn]
  }
}

resource "kubernetes_config_map" "decryptor" {
  metadata {
    name      = "keyclock-decryptor"
    namespace = local.namespace
  }

  data = {
    decryptor = <<EOT
#! /usr/bin/env python3
import glob
import os
def decrypt(string):
  import boto3
  import base64
  client = boto3.client('kms')
  meta = client.decrypt(CiphertextBlob=bytes(base64.b64decode("%s==" % string)),KeyId="${aws_kms_key.this.arn}")
  plaintext = meta[u'Plaintext']
  return plaintext.decode()
for file in glob.glob('./*.y*ml'):
  print("\n---")
  with open(file) as f:
    for line in f:
      if line.find("KMS_ENC:") > 0:
        encrypted = line.split("KMS_ENC")[1].split(":")[1]
        decrypted = decrypt(encrypted)
        line = line.replace("KMS_ENC:%s:" % encrypted, decrypted)
      print(line,end = '')
    EOT
  }
}
 
resource "local_file" "this" {
  count = local.argocd_enabled
  depends_on = [
    var.module_depends_on
  ]
  content  = yamlencode(local.application)
  filename = "${path.root}/${var.argocd.path}/${local.name}.yaml"
}

resource "random_password" "this" {
  length  = 20
  special = true
}

resource "aws_ssm_parameter" "this" {
  name        = "/${var.cluster_name}/keyclock/password"
  type        = "SecureString"
  value       = random_password.this.result
  description = "A password for accessing keyclock installation in ${var.cluster_name} EKS cluster"

  lifecycle {
    ignore_changes = [value]
  }

  tags = var.tags
}

resource "aws_ssm_parameter" "encrypted" {
  name        = "/${var.cluster_name}/keycolck/password/encrypted"
  type        = "SecureString"
  value       = bcrypt(random_password.this.result, 10)
  description = "An encrypted password for accessing keycolck installation in ${var.cluster_name} EKS cluster"

  lifecycle {
    ignore_changes = [value]
  }

  tags = var.tags
}

resource "aws_kms_key" "this" {
  description = "keycolck key"
  is_enabled  = true

  tags = var.tags
}

resource "aws_kms_ciphertext" "client_secret" {
  count     = lookup(var.oidc, "secret", null) == null ? 0 : 1
  key_id    = aws_kms_key.this.key_id
  plaintext = lookup(var.oidc, "secret", null)
}

locals {
  argocd_enabled = length(var.argocd) > 0 ? 1 : 0
  namespace      = coalescelist(kubernetes_namespace.this, [{ "metadata" = [{ "name" = var.namespace }] }])[0].metadata[0].name
  
    legacy_defaults = merge({
    "installCRDs"            = false
    "server.ingress.enabled" = length(var.domains) > 0 ? true : false
    "server.config.url"      = length(var.domains) > 0 ? "https://keycloak.${var.domains[0]}" : ""
    },
    { for i, domain in tolist(var.domains) : "server.ingress.tls[${i}].hosts[0]" => "keyclok.${domain}" },
    { for i, domain in tolist(var.domains) : "server.ingress.hosts[${i}]" => "keycloak.${domain}" },
    { for i, domain in tolist(var.domains) : "server.ingress.tls[${i}].secretName" => "keycloak-${domain}-tls" }
  )

  repository    = "https://charts.bitnami.com/bitnami"
  name                              = "keycloak"
  chart                             = "keycloak"
  conf          = merge(local.conf_defaults, var.conf)
  conf_defaults = merge({
    "rbac.create"                                               = true,
    "resources.limits.cpu"                                      = "100m",
    "resources.limits.memory"                                   = "2048Mi",
    "resources.requests.cpu"                                    = "512m",
    "resources.requests.memory"                                 = "512Mi",
    "aws.region"                                                = data.aws_region.current.name

    }
  )
 
   conf = {

    "configs.secret.createSecret"                                          = true
    "configs.secret.argocdServerAdminPassword"                             = aws_ssm_parameter.encrypted.value
    "global.securityContext.fsGroup"                                       = "999"
    "repoServer.env[0].name"                                               = "AWS_DEFAULT_REGION"
    "repoServer.env[0].value"                                              = data.aws_region.current.name
    "repoServer.serviceAccount.create"                                     = "true"
    "repoServer.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = module.iam_assumable_role_admin.iam_role_arn
    "repoServer.volumes[0].name"                                           = "decryptor"
    "repoServer.volumes[0].configMap.name"                                 = "keyclock-decryptor"
    "repoServer.volumes[0].configMap.items[0].key"                         = "decryptor"
    "repoServer.volumes[0].configMap.items[0].path"                        = "decryptor"
    "repoServer.volumeMounts[0].name"                                      = "decryptor"
    "repoServer.volumeMounts[0].mountPath"                                 = "/opt/decryptor/bin"
    "server.config.repositories"                                           = local.secrets_conf
    "server.config.configManagementPlugins" = yamlencode(
      [{
        "name" = "decryptor"
        "init" = {
          "command" = ["/usr/bin/pip3"]
          "args"    = ["install", "boto3"]
        }
        "generate" = {
          "command" = ["/usr/bin/python3"]
          "args"    = ["/opt/decryptor/bin/decryptor"]
        }
      }]
    )

    "server.service.type"    = "NodePort"
    "server.ingress.enabled" = length(var.domains) > 0 ? "true" : "false"
  }
  values = concat(coalescelist(
    [
      {
        "name"  = "server.rbacConfig.policy\\.csv"
        "value" = <<EOF
g, administrators, role:admin
EOF
      }
    ],
    [
      length(var.domains) == 0 ? null : {
        "name"  = "server.config.url"
        "value" = "https://keyclock.${var.domains[0]}"
      }
    ],
    [
      lookup(var.oidc, "id", null) == null && lookup(var.oidc, "pool", null) == null ? null : {
        "name" = "server.config.oidc\\.config"
        "value" = yamlencode(
          {
            "name"            = "Cognito"
            "issuer"          = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${lookup(var.oidc, "pool", "")}"
            "clientID"        = lookup(var.oidc, "id", "")
            "clientSecret"    = "KMS_ENC:${aws_kms_ciphertext.client_secret[0].ciphertext_blob}:"
            "requestedScopes" = ["openid", "profile", "email"]
            "requestedIDTokenClaims" = {
              "cognito:groups" = {
                "essential" = true
              }
            }
          }
        )
      }
    ]),
    values({
      for i, domain in tolist(var.domains) :
      "key" => {
        "name"  = "server.ingress.tls[${i}].hosts[0]"
        "value" = "keyclock.${domain}"
      }
    }),
    values({
      for i, domain in tolist(var.domains) :
      "key" => {
        "name"  = "server.ingress.hosts[${i}]"
        "value" = "keyclock.${domain}"
      }
    }),
    values({
      for i, domain in tolist(var.domains) :
      "key" => {
        "name"  = "server.ingress.tls[${i}].secretName"
        "value" = "keyclock-${domain}-tls"
      }
    }),
    values({
      for key, value in var.ingress_annotations :
      key => {
        "name"  = "server.ingress.annotations.${replace(key, ".", "\\.")}"
        "value" = value
      }
    }),
    values({
      for key, value in merge(local.conf, var.conf) :
      key => {
        "name"  = key
        "value" = tostring(value)
      }
    })
  )  
   application = {
    "apiVersion" = "argoproj.io/v1alpha1"
    "kind"       = "Application"
    "metadata" = {
      "name"      = local.name
      "namespace" = var.argocd.namespace
    }
    "spec" = {
      "destination" = {
        "namespace" = local.namespace
        "server"    = "https://kubernetes.default.svc"
      }
      "project" = "default"
      "source" = {
        "repoURL"        = local.repository
        "targetRevision" = var.chart_version
        "chart"          = var.chart_name
        "helm" = {
          "parameters" = values({
            for key, value in local.conf :
            key => {
              "name"  = key
              "value" = tostring(value)
            }
          })
        }
      }
      "syncPolicy" = {
        "automated" = {
          "prune"    = true
          "selfHeal" = true
        }
      }
