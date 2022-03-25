# Latest tags can be found here: https://github.com/lyft/terraform-orchestration-modules/tags
module "aws_provider_roles" {
  source = "git@github.com:lyft/terraform-orchestration-modules.git//ops/terraform/modules/data/aws_provider_roles/?ref=v3.4"
}

provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn = module.aws_provider_roles.zimride
  }
}
