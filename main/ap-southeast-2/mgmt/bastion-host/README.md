# Bastion Host

This folder creates a single EC2 instance that is meant to serve as a bastion host. A bastion host is a security best
practice where it is the *only* server exposed to the public. You must connect to it (e.g. via SSH) before you can
connect to any of your other servers, which are in private subnets. This way, you minimize the surface area you expose
to attackers, and can focus all your efforts on locking down just a single server.

## Current configuration

The bastion host in these templates has been configured as follows:

* **ssh-grunt**: We have installed [ssh-grunt](https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt)
  on the bastion host, so you can SSH to the server using your IAM username and a public key uploaded to your IAM
  account. Check out the [ssh-grunt docs](https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt)
  for more info.
* **SSH Key Pair**: The bastion host has also been configured to allow SSH access for the `ubuntu` user using the Key
  Pair `bastion-host-ap-southeast-2-v1`. *This should only be used as an emergency backup* (e.g. if for some reason `ssh-grunt` is not
  working). Only trusted administrators should have access to this Key Pair. If you don't have access to it, email
  support@gruntwork.io and we will share it with you securely (e.g. using [Keybase](http://keybase.io/)).
* **AMI**: The AMI that is running for Jenkins is created from the [Packer](https://www.packer.io/) template
  [infrastructure-modules/mgmt/bastion-host/packer/bastion-host.json](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/mgmt/bastion-host/packer/bastion-host.json)
  in the [infrastructure-modules](https://github.com/Veeps-Hosting/infrastructure-modules) repo.
* **Terragrunt**: Instead of using Terraform directly, we are using a wrapper called
  [Terragrunt](https://github.com/gruntwork-io/terragrunt) that provides locking and enforces best practices.
* **Terraform state**: We are using [Terraform Remote State](https://www.terraform.io/docs/state/remote/), which
  means the Terraform state files (the `.tfstate` files) are stored in an S3 bucket. If you use Terragrunt, it will
  automatically manage remote state for you based on the settings in the `terraform.tfvars` file.

## Where is the Terraform code?

All the Terraform code for this module is defined in [infrastructure-modules/mgmt/bastion-host](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/mgmt/bastion-host).
When you run Terragrunt, it finds the URL of this module in the `terraform.tfvars` file, downloads the Terraform code into
a temporary folder, copies all the files in the current working directory (including `terraform.tfvars`) into the
temporary folder, and runs your Terraform command in that temporary folder.

See the [Terragrunt Remote Terraform configurations
documentation](https://github.com/gruntwork-io/terragrunt#remote-terraform-configurations) for more info.

## Applying changes

To deploy a new AMI for the bastion host, update the Packer template
[infrastructure-modules/mgmt/bastion-host/packer/bastion-host.json](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/mgmt/bastion-host/packer/bastion-host.json)
build a new AMI, and use Terraform to deploy it. 

To deploy changes with Terraform, do the following:

1. Make sure [Terraform](https://www.terraform.io/) and [Terragrunt](https://github.com/gruntwork-io/terragrunt) are
   installed.
1. Configure the secrets specified at the top of `terraform.tfvars` as environment variables.
1. Run `terragrunt plan` to see the changes you're about to apply.
1. If the plan looks good, run `terragrunt apply`.

## Known errors

When you run `terraform apply` on these templates the first time, you may see the following error:

```
* aws_iam_instance_profile.bastion: diffs didn't match during apply. This is a bug with Terraform and should be reported as a GitHub Issue.
```

As the error implies, this is a Terraform bug, but fortunately, it's a harmless one related to the fact that AWS is
eventually consistent, and Terraform occasionally tries to use a recently-created resource that isn't yet available.
Just re-run `terraform apply` and the error should go away.

## More info

For more info, check out the Readme for this module in [infrastructure-modules/mgmt/bastion-host](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/mgmt/bastion-host).