# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform that supports locking and enforces best
# practices: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

terragrunt = {
  # Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
  # working directory, into a temporary folder, and execute your Terraform commands in that folder.
  terraform {
    source = "git::ssh://git@github.com/Veeps-Hosting/infrastructure-modules.git//security/iam-groups?ref=v0.0.1"
  }

  # Include all settings from the root terraform.tfvars file
  include = {
    path = "${find_in_parent_folders()}"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

should_require_mfa = true


iam_group_developers_permitted_services = ["ec2", "s3", "rds", "dynamodb", "elasticache"]
iam_group_developers_s3_bucket_prefix = "veeps-hosting-dev.user-"

iam_groups_for_cross_account_access = [
]
cross_account_access_all_group_name = "access-all-external-accounts"

should_create_iam_group_billing = true
should_create_iam_group_developers = true
should_create_iam_group_read_only = true
should_create_iam_group_ssh_grunt_sudo_users = true
should_create_iam_group_ssh_grunt_users = true
should_create_iam_group_use_existing_iam_roles = false
should_create_iam_group_auto_deploy = true

auto_deploy_permissions = [ "cloudwatch:*", "logs:*", "dynamodb:*", "ecr:*", "ecs:*", "route53:*", "s3:*", "autoscaling:*", "elasticloadbalancing:*", "iam:GetRole", "iam:GetRolePolicy", "iam:PassRole",  ]
