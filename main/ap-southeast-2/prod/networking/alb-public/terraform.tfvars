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
    source = "git::ssh://git@github.com/Veeps-Hosting/infrastructure-modules.git//networking/alb?ref=master"
  }

  # Include all settings from the root terraform.tfvars file
  include {
    path = "${find_in_parent_folders()}"
  }

  # When using the terragrunt xxx-all commands (e.g., apply-all, plan-all), deploy these dependencies before this module
  dependencies = {
    paths = ["../../vpc", "../../../../_global/route53-public", "../route53-private", "../../../mgmt/bastion-host"]
  }  
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------

alb_name = "prod-alb-public"
is_internal_alb = false

http_listener_ports = [80]

https_listener_ports_and_acm_ssl_certs = [
  {
    port            = 443
    tls_domain_name = "*.propertyiq-cloud.net"
  },
]

allow_inbound_from_cidr_blocks = [
  "0.0.0.0/0", # Allow all inbound requests for prod
]

num_days_after_which_archive_log_data = 30
num_days_after_which_delete_log_data = 60
access_logs_s3_bucket_name = "veeps-hosting-prod-alb-public-access-logs"

create_route53_entry = true
domain_name = "www.propertyiq-cloud.net"

