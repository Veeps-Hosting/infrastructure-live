# CloudTrail Logs

This Terraform Module enables [AWS CloudTrail](https://aws.amazon.com/cloudtrail/), a service for logging every API
call made against your AWS account. This is important in the case of audits, for debugging issues, and investigating
security breaches.
 
This module will create an S3 Bucket where CloudTrail events can be stored, a KMS Customer Master Key (CMK) used to 
encrypt CloudTrail events, and the CloudTrail "Trail" itself to enable API events to be recorded and stored in S3.

## Current configuration

The infrastructure in these templates has been configured as follows:

* **Terragrunt**: Instead of using Terraform directly, we are using a wrapper called
  [Terragrunt](https://github.com/gruntwork-io/terragrunt) that provides locking and enforces best practices.
* **Terraform state**: We are using [Terraform Remote State](https://www.terraform.io/docs/state/remote/), which
  means the Terraform state files (the `.tfstate` files) are stored in an S3 bucket. If you use Terragrunt, it will
  automatically manage remote state for you based on the settings in the `terraform.tfvars` file.

## Where is the Terraform code?

All the Terraform code for this module is defined in [infrastructure-modules/security/cloudtrail](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/security/cloudtrail).
When you run Terragrunt, it finds the URL of this module in the `terraform.tfvars` file, downloads the Terraform code into
a temporary folder, copies all the files in the current working directory (including `terraform.tfvars`) into the
temporary folder, and runs your Terraform command in that temporary folder.

See the [Terragrunt Remote Terraform configurations
documentation](https://github.com/gruntwork-io/terragrunt#remote-terraform-configurations) for more info.

## Applying changes

To apply changes to the templates in this folder, do the following:

1. Make sure [Terraform](https://www.terraform.io/) and [Terragrunt](https://github.com/gruntwork-io/terragrunt) are
   installed.
1. Configure the secrets specified at the top of `terraform.tfvars` as environment variables.
1. Run `terragrunt plan` to see the changes you're about to apply.
1. If the plan looks good, run `terragrunt apply`.

## Known Issues

- As of Terraform 0.9.8, Terraform will continue to modify the cloudtrail configuration on every run of `terragrunt plan`,
  even where this nothing to change. This is due to https://github.com/hashicorp/terraform/issues/13632. Repeatedly
  running `terragrunt apply` and making these changes is annoying but harmless.

## More info

For more info, check out the Readme for this module in [infrastructure-modules/security/cloudtrail](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/security/cloudtrail).