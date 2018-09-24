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
    source = "git::ssh://git@github.com/Veeps-Hosting/infrastructure-modules.git//mgmt/bastion-host?ref=master"
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
allow_ssh_from_cidr_list = [
  "203.217.18.248/32", # Veeps office 1
  "203.206.231.248/32", # Veeps office 2
  "202.8.64.0/24", # Veeps DC 1
  "203.19.79.0/24", # Veeps DC 2
  "122.106.231.223/32", # Veeps Grant Home
  "89.145.165.201/32", # 56K Office
  "62.203.52.138/32", # Brian Home Office
]
ami           = "ami-c975d6ab"
domain_name   = "bastion.aws.propertyiq-cloud.net"
instance_type = "t3.micro"
keypair_name  = "bastion-host-ap-southeast-2-v1"
name          = "bastion-host"
