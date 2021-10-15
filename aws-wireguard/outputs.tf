output "get_conf_command" {
  description = "Getting configuration for specific user"
  value       = <<-EOT
  aws --region=${local.region} lambda invoke --function-name ${module.create_user_conf.lambda_function_name} \
--payload '{ "user": "you_aws_username" }' --cli-binary-format raw-in-base64-out lambda-out.txt \
&& cat lambda-out.txt | jq -r  > wg.conf && rm lambda-out.txt
EOT
}
