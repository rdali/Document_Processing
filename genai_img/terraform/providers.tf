terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

#  backend "s3" {
#    bucket         = "terraform-state-bucket"
#    key            = "document-processor/terraform.tfstate"
#    region         = "us-east-1"
#    encrypt        = true
#    dynamodb_table = "terraform-state-table"
#  }
}

provider "aws" {
  region = var.aws_region
} 