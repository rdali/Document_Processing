# https://registry.terraform.io/modules/aws-ia/bedrock/aws/latest
# https://github.com/aws-ia/terraform-aws-bedrock/blob/main/bda.tf


resource "awscc_bedrock_blueprint" "bda_blueprint" {
    blueprint_name         = "${var.project_name}-bda-blueprint-${var.env}"
    schema                 = var.blueprint_schema
    type                   = var.blueprint_type
}


resource "awscc_bedrock_data_automation_project" "bda_project" {
    project_name                  = "${var.project_name}-bda-project-${var.env}"
    project_description           = var.bda_project_description
    custom_output_configuration   = {
        blueprints = [
            {
                blueprint_arn = awscc_bedrock_blueprint.bda_blueprint.blueprint_arn 
                blueprint_stage = awscc_bedrock_blueprint.bda_blueprint.blueprint_stage 
            }
        ]
    }
}


