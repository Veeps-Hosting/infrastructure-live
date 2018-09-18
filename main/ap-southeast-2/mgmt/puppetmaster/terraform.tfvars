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
    source = "git::ssh://git@github.com/Veeps-Hosting/infrastructure-modules.git//mgmt/puppetmaster?ref=master"
  }

  # Include all settings from the root terraform.tfvars file
  include = {
    path = "${find_in_parent_folders()}"
  }

  # When using the terragrunt xxx-all commands (e.g., apply-all, plan-all), deploy these dependencies before this module
  dependencies = {
    paths = ["../vpc", "../../../_global/route53-public", "../../_global/sns-topics"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------
ami           = "ami-07a3bd4944eb120a0"
dns_zone_id   = "Z3EDT3G8560CK3"
dns_name      = "puppet.propertyiq-cloud.net"
instance_type = "t3.medium"
name          = "puppet"
keypair_name  = ""
