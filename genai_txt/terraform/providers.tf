terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }

#  backend "s3" {
#    bucket         = "terraform-state-bucket"
#    key            = "document-processor/terraform.tfstate"
#    region         = "us-east-2"
#    encrypt        = true
#    dynamodb_table = "terraform-state-table"
#  }
}

provider "aws" {
  region = var.aws_region
} 