# Simple Notification Service (SNS) Topics

This directory creates Topics for Amazon's [Simple Notification Service (SNS)](https://aws.amazon.com/sns/). The
resources managed by these templates are:

* An SNS topic for CloudWatch alarms. You can subscribe to this topic in the [SNS
  Console](https://console.aws.amazon.com/sns/v2/home#/topics) to be notified of alarms by email or text message.

## Current configuration

The infrastructure in these templates has been configured as follows:

* **Terragrunt**: Instead of using Terraform directly, we are using a wrapper called
  [Terragrunt](https://github.com/gruntwork-io/terragrunt) that provides locking and enforces best practices.
* **Terraform state**: We are using [Terraform Remote State](https://www.terraform.io/docs/state/remote/), which
  means the Terraform state files (the `.tfstate` files) are stored in an S3 bucket. If you use Terragrunt, it will
  automatically manage remote state for you based on the settings in the `terraform.tfvars` file.

## Where is the Terraform code?

All the Terraform code for this module is defined in [infrastructure-modules/networking/sns-topics](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/networking/sns-topics).
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

## More info

For more info, check out the Readme for this module in [infrastructure-modules/networking/sns-topics](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/networking/sns-topics).