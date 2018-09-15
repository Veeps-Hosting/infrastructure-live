# Sample-App-Backend-Asg-Prod

This directory deploys the sample-app-backend-asg-prod in an Auto Scaling Group (ASG) in the prod VPC. Under the hood,
this is implemented using Terraform modules from [infrastructure-modules/services/asg-service](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/services/asg-service).





## Current configuration

The infrastructure in these templates has been configured as follows:

* **ssh-grunt**: We have installed [ssh-grunt](https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt)
  on each EC2 Instance in the ASG, so you can SSH to each server using your IAM username and a public key uploaded to
  your IAM account. Check out the [ssh-grunt docs](https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt)
  for more info.
* **SSH Key Pair**: The EC2 Instances have also been configured to allow SSH access using the Key Pair
  `prod-services-ap-southeast-2-v1`. *This should only be used as an emergency backup* (e.g. if for some reason `ssh-grunt` is not
  working). Only trusted administrators should have access to this Key Pair. If you don't have access to it, email
  support@gruntwork.io and we will share it with you securely (e.g. using [Keybase](http://keybase.io/)).
* **Terragrunt**: Instead of using Terraform directly, we are using a wrapper called
  [Terragrunt](https://github.com/gruntwork-io/terragrunt) that provides locking and enforces best practices.
* **Terraform state**: We are using [Terraform Remote State](https://www.terraform.io/docs/state/remote/), which
  means the Terraform state files (the `.tfstate` files) are stored in an S3 bucket. If you use Terragrunt, it will
  automatically manage remote state for you based on the settings in the `terraform.tfvars` file.





## Where is the Terraform code?

All the Terraform code for this module is defined in [infrastructure-modules/services/asg-service](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/services/asg-service).
When you run Terragrunt, it finds the URL of this module in the `terraform.tfvars` file, downloads the Terraform code into
a temporary folder, copies all the files in the current working directory (including `terraform.tfvars`) into the
temporary folder, and runs your Terraform command in that temporary folder.

See the [Terragrunt Remote Terraform configurations
documentation](https://github.com/gruntwork-io/terragrunt#remote-terraform-configurations) for more info.





## Applying changes

To deploy a new version of the service:

1. Make sure [Terraform](https://www.terraform.io/) and [Terragrunt](https://github.com/gruntwork-io/terragrunt) are
   installed.
1. Update the `version` input in `main.tf`.
1. Configure the secrets specified at the top of `terraform.tfvars` as environment variables.
1. Run `terragrunt plan` to see the changes you're about to apply.
1. If the plan looks good, run `terragrunt apply`.




## More info

For more info, check out the Readme for this module in [infrastructure-modules/services/asg-service](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/services/asg-service).