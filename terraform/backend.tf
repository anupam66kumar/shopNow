terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket         = "project4-shopnow-tfstate-951066974787"
    key            = "eks/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "project4-terraform-locks"
  }
}
