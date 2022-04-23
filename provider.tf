terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.10.0"
    }
    github = {
      source  = "integrations/github"
      version = "4.23.0"
    }
  }
}

provider "github" {
  # Configuration options
  token = "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"
}

provider "aws" {
  # Configuration options
  region  = "us-east-1"
  profile = "ben"
}
