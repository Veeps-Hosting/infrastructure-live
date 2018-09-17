# These variables apply to this entire AWS account. They are automatically pulled in using the extra_arguments
# setting in the root terraform.tfvars file's Terragrunt configuration.
aws_account_id             = "159447213031"
terraform_state_s3_bucket  = "veeps-hosting-main-terraform-state"
terraform_state_aws_region = "ap-southeast-2"