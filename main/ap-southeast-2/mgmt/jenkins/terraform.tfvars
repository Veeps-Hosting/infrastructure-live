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
    source = "git::ssh://git@github.com/Veeps-Hosting/infrastructure-modules.git//mgmt/jenkins?ref=master"
  }

  # Include all settings from the root terraform.tfvars file
  include = {
    path = "${find_in_parent_folders()}"
  }

  # When using the terragrunt xxx-all commands (e.g., apply-all, plan-all), deploy these dependencies before this module
  dependencies = {
    paths = ["../vpc", "../bastion-host", "../../_global/sns-topics", "../../../_global/route53-public"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------
acm_ssl_certificate_domain = "*.propertyiq-cloud.net"
ami                        = "ami-01098c28fa65dc849"
domain_name                = "jenkins.propertyiq-cloud.net"
instance_type              = "t2.small"
jenkins_volume_size        = 200
jenkins_volume_encrypted   = true
keypair_name               = "jenkins-ap-southeast-2-v1"
memory                     = "1024m"
tenancy                    = "default"
