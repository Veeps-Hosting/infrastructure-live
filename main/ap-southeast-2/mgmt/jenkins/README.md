# Jenkins

This directory deploys [Jenkins](https://jenkins.io/).

## Current configuration

The infrastructure in these templates has been configured as follows:

* **ssh-grunt**: We have installed [ssh-grunt](https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt)
  on the Jenkins host, so you can SSH to the server using your IAM username and a public key uploaded to your IAM
  account. Check out the [ssh-grunt docs](https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt)
  for more info.
* **SSH Key Pair**: The Jenkins host has also been configured to allow SSH access for the `ubuntu` user using the Key
  Pair `jenkins-ap-southeast-2-v1`. *This should only be used as an emergency backup* (e.g. if for some reason `ssh-grunt` is not
  working). Only trusted administrators should have access to this Key Pair. If you don't have access to it, email
  support@gruntwork.io and we will share it with you securely (e.g. using [Keybase](http://keybase.io/)).
* **AMI**: The AMI that is running for Jenkins is created from the [Packer](https://www.packer.io/) template
  [infrastructure-modules/mgmt/jenkins/packer/jenkins-ubuntu.json](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/mgmt/jenkins/packer/jenkins-ubuntu.json)
  in the [infrastructure-modules](https://github.com/Veeps-Hosting/infrastructure-modules) repo.
* **IAM Permissions**: In order for Jenkins to be able to do automatic deployment by running Terraform, we have given
  it IAM permissions to access a large number of AWS APIs. This means Jenkins is a highly trusted actor and we need to
  be extra careful in how we manage and secure it.
* **Terragrunt**: Instead of using Terraform directly, we are using a wrapper called
  [Terragrunt](https://github.com/gruntwork-io/terragrunt) that provides locking and enforces best practices.
* **Terraform state**: We are using [Terraform Remote State](https://www.terraform.io/docs/state/remote/), which
  means the Terraform state files (the `.tfstate` files) are stored in an S3 bucket. If you use Terragrunt, it will
  automatically manage remote state for you based on the settings in the `terraform.tfvars` file.

## Where is the Terraform code?

All the Terraform code for this module is defined in [infrastructure-modules/mgmt/jenkins](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/mgmt/jenkins).
When you run Terragrunt, it finds the URL of this module in the `terraform.tfvars` file, downloads the Terraform code into
a temporary folder, copies all the files in the current working directory (including `terraform.tfvars`) into the
temporary folder, and runs your Terraform command in that temporary folder.

See the [Terragrunt Remote Terraform configurations
documentation](https://github.com/gruntwork-io/terragrunt#remote-terraform-configurations) for more info.

## Applying changes

To deploy a new version of Jenkins, update the Packer template
[infrastructure-modules/mgmt/jenkins/packer/jenkins-ubuntu.json](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/mgmt/jenkins/packer/jenkins-ubuntu.json),
build a new AMI, and use Terraform to deploy it.

To deploy changes with Terraform, do the following:

1. Make sure [Terraform](https://www.terraform.io/) and [Terragrunt](https://github.com/gruntwork-io/terragrunt) are
   installed.
1. Configure the secrets specified at the top of `terraform.tfvars` as environment variables.
1. Run `terragrunt plan` to see the changes you're about to apply.
1. If the plan looks good, run `terragrunt apply`.

## More info

For more info, check out the Readme for this module in [infrastructure-modules/mgmt/jenkins](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/mgmt/jenkins).