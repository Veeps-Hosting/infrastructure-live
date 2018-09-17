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
    source = "git::ssh://git@github.com/Veeps-Hosting/infrastructure-modules.git//security/cloudtrail?ref=master"
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

cloudtrail_trail_name = "veeps-hosting"
s3_bucket_name = "veeps-hosting-cloudtrail-logs"

num_days_after_which_archive_log_data = 30
num_days_after_which_delete_log_data = 365

kms_key_administrator_iam_arns = ["arn:aws:iam::159447213031:user/grant.davies"]
kms_key_user_iam_arns = ["arn:aws:iam::159447213031:user/grant.davies"]
allow_cloudtrail_access_with_iam = true

s3_bucket_already_exists = false
external_aws_account_ids_with_write_access = []
