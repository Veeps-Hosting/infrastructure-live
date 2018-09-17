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

name = "bastion-host"
instance_type = "t2.micro"
ami = "ami-08fe42975de5a0d04"

domain_name = "bastion.propertyiq-cloud.net"

keypair_name = "bastion-host-ap-southeast-2-v1"
allow_ssh_from_cidr_list = [
  "203.217.18.248/32", # Veeps IP #4
  "203.206.231.248/32", # Veeps IP #5
  "37.228.252.224/32", # Jim (Gruntwork) IP at home
  "202.8.64.0/24", # Veeps IP #1
  "203.19.79.0/24", # Veeps IP #2
  "122.106.231.223/32", # Veeps IP #3
]