# Create namespace
resource "kubernetes_namespace" "this" {
  depends_on = [
    var.module_depends_on
  ]
  count = var.namespace == "" ? 1 : 0
  metadata {
    name = var.namespace_name
  }
}

# Deploy CVAT using a Helm chart
resource "helm_release" "cvat" {
  depends_on = [
    var.module_depends_on
  ]
  name          = local.name
  namespace     = local.namespace
  chart         = "${path.module}/helm"
  recreate_pods = true
  timeout       = 1200

  values = [templatefile("${path.module}/helm/cvat.yaml",
    {
      cvat_url            = "cvat.${var.domains[0]}"
      cvat_tag            = var.cvat_tag
      postgresql_local    = var.cvat_postgresql_local
      postgresql_host     = var.cvat_postgresql_host
      postgresql_port     = var.cvat_postgresql_port
      postgresql_username = var.cvat_postgresql_username
      postgresql_password = var.cvat_postgresql_local ? random_password.cvat_postgresql_password.result : var.cvat_postgresql_password
      postgresql_database = var.cvat_postgresql_database
      redis_local         = var.cvat_redis_local
      redis_host          = var.cvat_redis_host
      redis_port          = var.cvat_redis_port
      redis_username      = var.cvat_redis_username
      redis_password      = var.cvat_redis_local ? random_password.cvat_redis_password.result : var.cvat_redis_password
    })
  ]
}

#Password generator
resource "random_password" "cvat_postgresql_password" {
  length           = 16
  special          = true
  override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "cvat_postgresql_password" {
  name  = "/cvat/${var.cluster_name}/${var.cvat_postgresql_username}"
  type  = "SecureString"
  value = random_password.cvat_postgresql_password.result
}

resource "random_password" "cvat_redis_password" {
  length           = 16
  special          = true
  override_special = "!#%&*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "cvat_redis_password" {
  name  = "/cvat/${var.cluster_name}/${var.cvat_redis_username}"
  type  = "SecureString"
  value = random_password.cvat_redis_password.result
}

locals {
  name      = "cvat"
  namespace = coalescelist(kubernetes_namespace.this, [{ "metadata" = [{ "name" = var.namespace }] }])[0].metadata[0].name
}
