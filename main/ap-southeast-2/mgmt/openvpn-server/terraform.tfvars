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
    source = "git::ssh://git@github.com/Veeps-Hosting/infrastructure-modules.git//mgmt/openvpn-server?ref=v0.0.1"
  }

  # Include all settings from the root terraform.tfvars file
  include = {
    path = "${find_in_parent_folders()}"
  }

  # When using the terragrunt xxx-all commands (e.g., apply-all, plan-all), deploy these dependencies before this module
  dependencies = {
    paths = ["../vpc", "../kms-master-key", "../../../_global/route53-public", "../../stage/vpc", "../../prod/vpc", "../../_global/sns-topics"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
# ---------------------------------------------------------------------------------------------------------------------

name = "openvpn"
instance_type = "t2.medium"
ami = "ami-00ba2192f2baf1d44"

domain_name = "vpn.propertyiq-cloud.net"
create_route53_entry = true

request_queue_name = "openvpn-request-queue"
revocation_queue_name = "openvpn-revocation-queue"

backup_bucket_name = "veeps-hosting-mgmt-openvpn-backup"

# VPN clients will be assigned (internal) IP addresses from this range of IPs
vpn_subnet = "172.16.1.0 255.255.255.0"

# The OpenVPN server is configured in split tunnel mode, so only specific IP address ranges will be routed over the VPN
# connection. That way, only requests for internal AWS resources go over VPN, and not your normal web traffic (e.g.
# GMail, Spotify, YouTube, etc). Here, we configure the module with the names of all of our VPCs, so all traffic to the
# IP address ranges of those VPCs will be sent over VPN.
current_vpc_name = "mgmt"
other_vpc_names = ["stage", "prod"]

ca_country = "AU"
ca_state = "NSW"
ca_locality = "Neutral Bay"
ca_org = "Veeps Hosting"
ca_org_unit = "IT"
ca_email = "grant@veepshosting.com"
        
keypair_name = "openvpn-ap-southeast-2-v1"
allow_ssh_from_cidr_list = [
  "203.217.18.248/32", # Veeps IP #4
  "203.206.231.248/32", # Veeps IP #5
  "37.228.252.224/32", # Jim (Gruntwork) IP at home
  "202.8.64.0/24", # Veeps IP #1
  "203.19.79.0/24", # Veeps IP #2
  "122.106.231.223/32", # Veeps IP #3
]