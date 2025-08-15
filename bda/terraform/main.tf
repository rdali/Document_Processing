#-----

module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  env = var.env
  aws_region = var.aws_region
  extensions = var.extensions
  lambda_trigger_bda_arn = module.lambda.lambda_trigger_bda_arn
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  env = var.env
  input_bucket_arn = module.storage.input_bucket_arn
  output_bucket_arn = module.storage.output_bucket_arn
}

module "lambda" {
  source       = "./modules/lambda"
  project_name = var.project_name
  env = var.env
  aws_region = var.aws_region
  s3_bucket_inputs_name = module.storage.input_bucket_name
  s3_bucket_outputs_name = module.storage.output_bucket_name
  lambda_role_bda_arn = module.iam.iam_lambda_trigger_bda_role_arn
  input_bucket_arn = module.storage.input_bucket_arn
  output_bucket_arn = module.storage.output_bucket_arn
  data_automation_project_arn = module.bedrock.data_automation_project_arn
  bda_blueprint_arn = module.bedrock.bda_blueprint_arn
}

module "bedrock" {
  source       = "./modules/bedrock"
  project_name = var.project_name
  env = var.env
  bda_project_description = var.bda_project_description 
  blueprint_schema = file(var.blueprint_schema_file)
  blueprint_type = var.blueprint_type
}



