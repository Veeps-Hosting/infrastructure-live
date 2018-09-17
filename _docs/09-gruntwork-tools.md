# Gruntwork Tools

Just in case you missed them earlier in the tutorial, here are some useful Gruntwork tools:

- **[aws-auth](https://github.com/gruntwork-io/module-security/tree/master/modules/aws-auth):** A bash script that
makes it easy to switch between multiple AWS accounts and use MFA in the CLI.

- **[gruntkms](https://github.com/gruntwork-io/gruntkms)**: Use this tool to to encrypt/decrypt secrets with 
  [Amazon's Key Management Service](https://aws.amazon.com/documentation/kms/) using a one-line command.

- **[terragrunt](https://github.com/gruntwork-io/terragrunt)**: Terragrunt is a thin wrapper for Terraform that provides
  extra tools for working with multiple Terraform modules. You should always use Terragrunt with this repo.

- **[ssh-grunt](https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt)**: Your EC2 Instances use
  this tool to allow SSH access to be managed via the IAM User console.  

To see a full list of all Gruntwork Infrastructure Packages and tools, see the [Gruntwork Table of 
Contents](https://github.com/gruntwork-io/toc).



## Next steps

Next up, you'll learn how to [migrate your apps to the Reference Architecture](10-migration.md).