# Latest tags can be found here: https://github.com/lyft/terraform-orchestration-modules/tags
module "service_role" {
  source       = "git@github.com:lyft/terraform-orchestration-modules.git//ops/terraform/modules/iam_role?ref=v3.4"
  service_name = "maplibreglnativeprivate"
  environment  = "production"
}
