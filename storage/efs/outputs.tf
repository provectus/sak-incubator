output "aws_efs_file_system_id" {
  value = aws_efs_file_system.this.id
}

output "aws_efs_access_point_id" {
  value = aws_efs_access_point.this.id
}

output "pvc_name" {
  value = var.pvc_name
}
