# puppetmaster
This folder creates a single EC2 instance that is meant to serve as a puppet master.

## Current configuration

The puppetmaster in these templates has been configured as follows:

## Where is the Terraform code?

All the Terraform code for this module is defined in [infrastructure-modules/mgmt/puppetmaster](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/mgmt/puppetmaster).
When you run Terragrunt, it finds the URL of this module in the `terraform.tfvars` file, downloads the Terraform code into
a temporary folder, copies all the files in the current working directory (including `terraform.tfvars`) into the
temporary folder, and runs your Terraform command in that temporary folder.

See the [Terragrunt Remote Terraform configurations
documentation](https://github.com/gruntwork-io/terragrunt#remote-terraform-configurations) for more info.

To deploy changes with Terraform, do the following:

1. Make sure [Terraform](https://www.terraform.io/) and [Terragrunt](https://github.com/gruntwork-io/terragrunt) are
   installed.
1. Configure the secrets specified at the top of `terraform.tfvars` as environment variables.
1. Run `terragrunt plan` to see the changes you're about to apply.
1. If the plan looks good, run `terragrunt apply`.

## Known errors

When you run `terraform apply` on these templates the first time, you may see the following error:

```
* aws_iam_instance_profile.puppetmaster: diffs didn't match during apply. This is a bug with Terraform and should be reported as a GitHub Issue.
```

As the error implies, this is a Terraform bug, but fortunately, it's a harmless one related to the fact that AWS is
eventually consistent, and Terraform occasionally tries to use a recently-created resource that isn't yet available.
Just re-run `terraform apply` and the error should go away.

## More info

For more info, check out the Readme for this module in [infrastructure-modules/mgmt/puppetmaster](https://github.com/Veeps-Hosting/infrastructure-modules/tree/master/mgmt/puppetmaster).
