# Route53 Private Hosted Zones

This directory manages private DNS entries using [Amazon Route 53](https://aws.amazon.com/route53/). 

For each domain name (e.g. example.com) you pass in, this module will create a [Route 53 Private Hosted 
Zone](http://docs.aws.amazon.com/Route53/latest/DeveloperGuide/AboutHZWorkingWith.html) in the VPC specified via the 
`vpc_name` input variable. The Terraform configurations for each app are responsible for adding their individual DNS 
records (e.g. foo.example.com) to this Hosted Zone.




## Current configuration

The infrastructure in these templates has been configured as follows:

* **Terragrunt**: Instead of using Terraform directly, we are using a wrapper called
  [Terragrunt](https://github.com/gruntwork-io/terragrunt) that provides locking and enforces best practices.
* **Terraform state**: We are using [Terraform Remote State](https://www.terraform.io/docs/state/remote/), which
  means the Terraform state files (the `.tfstate` files) are stored in an S3 bucket. If you use Terragrunt, it will
  automatically manage remote state for you based on the settings in the `terraform.tfvars` file.




## Where is the Terraform code?

All the Terraform code for this module is defined in [infrastructure-modules/networking/route53-private](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/networking/route53-private).
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

For more info, check out the Readme for this module in [infrastructure-modules/networking/route53-private](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/networking/route53-private).