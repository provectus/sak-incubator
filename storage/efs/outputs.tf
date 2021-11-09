output "aws_efs_file_system_id" {
  value = aws_efs_file_system.this.id
}

output "pvc" {
  value = kubernetes_persistent_volume_claim.this
}
