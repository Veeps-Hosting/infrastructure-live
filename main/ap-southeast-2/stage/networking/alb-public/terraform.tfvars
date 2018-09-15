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
    source = "git::ssh://git@github.com/Veeps-Hosting/infrastructure-modules.git//networking/alb?ref=v0.0.1"
  }

  # Include all settings from the root terraform.tfvars file
  include {
    path = "${find_in_parent_folders()}"
  }

  # When using the terragrunt xxx-all commands (e.g., apply-all, plan-all), deploy these dependencies before this module
  dependencies = {
    paths = ["../../vpc", "../../../../_global/route53-public", "../route53-private", "../../../mgmt/openvpn-server"]
  }  
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------

alb_name = "stage-alb-public"
is_internal_alb = false

http_listener_ports = [80]

https_listener_ports_and_acm_ssl_certs = [
  {
    port            = 443
    tls_domain_name = "*.propertyiq-cloud.net"
  },
]

allow_inbound_from_cidr_blocks = [
  "203.217.18.248/32", # Veeps IP #4
  "203.206.231.248/32", # Veeps IP #5
  "37.228.252.224/32", # Jim (Gruntwork) IP at home
  "202.8.64.0/24", # Veeps IP #1
  "203.19.79.0/24", # Veeps IP #2
  "122.106.231.223/32", # Veeps IP #3
]

num_days_after_which_archive_log_data = 30
num_days_after_which_delete_log_data = 60
access_logs_s3_bucket_name = "veeps-hosting-stage-alb-public-access-logs"

create_route53_entry = true
domain_name = "stage.propertyiq-cloud.net"

