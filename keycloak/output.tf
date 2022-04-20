output "path_to_keycloak_password" {
  value       = aws_ssm_parameter.keycloak_password.id
  description = "A SystemManager ParemeterStore key with keycloak admin password"
}