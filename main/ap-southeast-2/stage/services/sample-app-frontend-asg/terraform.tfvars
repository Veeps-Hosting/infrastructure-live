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
    source = "git::ssh://git@github.com/Veeps-Hosting/infrastructure-modules.git//services/asg-service?ref=master"
  }

  # Include all settings from the root terraform.tfvars file
  include = {
    path = "${find_in_parent_folders()}"
  }

  # When using the terragrunt xxx-all commands (e.g., apply-all, plan-all), deploy these dependencies before this module
  dependencies = {
    paths = ["../../vpc", "../../data-stores/aurora", "../../networking/alb-public", "../../../_global/sns-topics", "../../../../us-east-1/_global/sns-topics", "../../kms-master-key"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------

name = "sample-app-frontend-asg-stage"
ami = "ami-068e2cbc02ea7d18b"
init_script_path = "/opt/sample-app-frontend/bin/run-app.sh"
server_port = 8080

instance_type = "t3.micro"
keypair_name = "stage-services-ap-southeast-2-v1"

min_size = 2
max_size = 2
desired_capacity = 2
min_elb_capacity = 2

db_remote_state_path = "data-stores/aurora/terraform.tfstate"

health_check_path = "/sample-app-frontend/health"
health_check_protocol = "HTTPS"

is_internal_alb = false

# Attach these routing rules to the ALB. These rules configure the ALB to send requests that come in on certain ports
# and paths to this ASG service.
alb_listener_rule_configs = [
  {
    port     = 80,
    path     = "/sample-app-frontend*",
    priority = 110
  },
  {
    port     = 443,
    path     = "/sample-app-frontend*",
    priority = 110
  },
]
