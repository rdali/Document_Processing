output "input_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = module.storage.input_bucket_name
}

output "output_bucket_name" {
  description = "Name of the created S3 bucket"
  value       = module.storage.output_bucket_name
}

output "blueprint_arn" {
  value = module.bedrock.bda_blueprint.blueprint_arn
}

