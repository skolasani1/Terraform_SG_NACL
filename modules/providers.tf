terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.45.0"
    }
  }

  backend "s3" {
    bucket = "terraform-vpc-bucket"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}
