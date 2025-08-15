output "bda_blueprint" {
  value       = awscc_bedrock_blueprint.bda_blueprint
  description = "The BDA blueprint"
}

output "bda_blueprint_arn" {
  value       = awscc_bedrock_blueprint.bda_blueprint.blueprint_arn
  description = "The BDA blueprint ARN"
}

output "data_automation_project_arn" {
  description = "The ARN of the BDA project."
  value       = awscc_bedrock_data_automation_project.bda_project.project_arn
}