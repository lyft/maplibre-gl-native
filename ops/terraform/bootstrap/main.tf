# Latest tags can be found here: https://github.com/lyft/terraform-orchestration-modules/tags
module "aws_provider_roles" {
  source = "git@github.com:lyft/terraform-orchestration-modules.git//ops/terraform/modules/data/aws_provider_roles/?ref=v3.4"
}

provider "aws" {
  region = "us-east-1"
  alias  = "primary"
  assume_role {
    role_arn = module.aws_provider_roles.zimride
  }
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.67.0"
    }
  }
}
provider "aws" {
  region = "us-west-2"
  alias  = "backup"
  assume_role {
    role_arn = module.aws_provider_roles.zimride
  }
}
