# Latest tags can be found here: https://github.com/lyft/terraform-orchestration-modules/tags
module "ecr" {
  source       = "git@github.com:lyft/terraform-orchestration-modules.git//ops/terraform/modules/ecr?ref=v3.4"
  project_name = "maplibreglnativeprivate"

  providers = {
    aws.primary = aws.primary
    aws.backup  = aws.backup
  }
}
