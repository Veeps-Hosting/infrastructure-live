# ---------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# ---------------------------------------------------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# TF_VAR_master_password

# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# This is the configuration for Terragrunt, a thin wrapper for Terraform that supports locking and enforces best
# practices: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------

terragrunt = {
  # Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
  # working directory, into a temporary folder, and execute your Terraform commands in that folder.
  terraform {
    source = "git::ssh://git@github.com/Veeps-Hosting/infrastructure-modules.git//data-stores/aurora?ref=v0.0.1"
  }

  # Include all settings from the root terraform.tfvars file
  include = {
    path = "${find_in_parent_folders()}"
  }

  # When using the terragrunt xxx-all commands (e.g., apply-all, plan-all), deploy these dependencies before this module
  dependencies = {
    paths = ["../../vpc", "../../kms-master-key", "../../../mgmt/openvpn-server", "../../../_global/sns-topics"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------

name = "aurora-prod"
port = 3306
engine = "aurora"
db_name = "example"

master_username = "master"
# The master_password should be set using the environment variable TF_VAR_master_password

instance_count = 2
instance_type = "db.r4.large"
storage_encrypted = false

backup_retention_period = 21
apply_immediately = false
allow_connections_from_openvpn_server = false

# Trigger an alarm if the DB has more than 100 connections
too_many_db_connections_threshold = 100

# Trigger an alarm if the DB is using more than 90% of its CPU over a 5 minute period
high_cpu_utilization_threshold = 90
high_cpu_utilization_period = 300

# Trigger an alarm if the DB has less than 100MB of memory available over a 5 minute period
low_memory_available_threshold = 100000000
low_memory_available_period = 300

# Trigger an alarm if the DB has less than 1GB of disk space available over a 1 minute period
low_disk_space_available_threshold = 1000000000
low_disk_space_available_period = 60

# Disable the alarms for read and write latency until we know the expected DB performance
enable_perf_alarms = false