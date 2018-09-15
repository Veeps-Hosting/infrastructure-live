# Live Infrastructure

This repository contains [Terraform](https://www.terraform.io/) code to deploy the live, running infrastructure for 
Veeps Hosting in AWS. This code uses the Terraform modules from the 
[infrastructure-modules](https://github.com/Veeps-Hosting/infrastructure-modules) repository.

Note that some of these modules rely on modules that are part of [Gruntwork](http://www.gruntwork.io) Infrastructure 
Packages. The Gruntwork modules live in private Git repos, and if you don't have access to those repos, please email
[support@gruntwork.io](mailto:support@gruntwork.io).

## Start here

If you're new to this infrastructure, Terraform, or AWS, make sure to start with the end-to-end 
[Infrastructure Walkthrough Documentation](/_docs). 

## Overview of the infrastructure managed in these templates

The infrastructure in this repo uses the following file/folder layout:
 
```
account
 └ _global
 └ region
    └ _global
    └ environment
       └ resource
```

The hierarchy of folders is as follows:

* **Account**: At the top level are each of your AWS accounts, such as `stage-account`, `prod-account`, `mgmt-account`, 
  etc. If you have everything deployed in a single AWS account, there will just be a single folder at the root (e.g. 
  `main-account`).
  
* **Region**: Within each account, there will be one or more [AWS 
  regions](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html), such as 
  `us-east-1`, `eu-west-1`, and `ap-southeast-2`, where you've deployed resources. There may also be a `_global` 
  folder that defines resources that are available across all the AWS regions in this account, such as IAM users, 
  Route 53 hosted zones, and CloudTrail. 

* **Environment**: Within each region, there will be one or more "environments", such as `qa`, `stage`, etc. Typically, 
  an environment will correspond to a single [AWS Virtual Private Cloud (VPC)](https://aws.amazon.com/vpc/), which 
  isolates that environment from everything else in that AWS account. There may also be a `global` folder 
  that defines resources that are available across all the environments in this AWS region, such as Route 53 A records, 
  SNS topics, and ECR repos.
  
* **_Global**: At the "region" and "environment" levels, the `_global` folder contains resources that are "global" to
  all AWS Regions (e.g. IAM Users are not region-specific, or "global" to all environments in that region (e.g. SNS Topics
  do not exist within a VPC but are specific to an AWS Region).

* **Resource**: Within each environment, you deploy all the resources for that environment, such as EC2 Instances, Auto
  Scaling Groups, ECS Clusters, Databases, Load Balancers, and so on. Note that the Terraform code for most of these
  resources lives in the [infrastructure-modules](https://github.com/Veeps-Hosting/infrastructure-modules)
  repository.

Here's an example:

```
account-test
 └ _global
 └ us-east-1
    └ _global
    └ qa
       └ vpc
       └ data-stores
       └ services
    └ stage
       └ vpc
       └ data-stores
       └ services
       
account-prod
 └ _global
 └ us-east-1
    └ _global
    └ prod
       └ vpc
       └ data-stores
       └ services
```

## How do you apply changes to this infrastructure?

See the README for each folder for instructions. Also, check out the README in the
[infrastructure-modules](https://github.com/Veeps-Hosting/infrastructure-modules)
repo for details on how this code is versioned and how to promote a version from environment to environment.

## What is Terraform?

[Terraform](https://www.terraform.io/) is an open source tool used to define, provision, and manage
infrastructure-as-code. Just as every developer today knows to version control their app code, infrastructure-as-code
allows you to version control your infrastructure. This allows you to:

* Maintain an audit trail of all changes.
* Use the Pull Request methodology to propose changes and encourage peer review prior to pushing to production.
* Maintain a level of rigor around how infrastructure is managed.
* Create validation tests that must pass before infrastructure changes can be approved.

Learn more about using Terraform by checking out their [documentation](https://www.terraform.io/docs/index.html).

## How are the Terraform templates in this repo organized?

For the most part, the Terraform templates in this repo just assemble self-contained "modules" defined in the
[infrastructure-modules](https://github.com/Veeps-Hosting/infrastructure-modules) 
repo. Think of the modules as reusable blueprints and the templates in this repo as real houses built from those 
blueprints.

The advantages of this approach are:

1. You can define reusable pieces of infrastructure in modules.
2. You can test each module in isolation.
3. You can version each module separately and thereby experiment with different versions of your infrastructure in
   different environments (e.g. try a new database in staging before production).

## Why are all the accounts, regions, and environments in separate folders?

The reason we keep each account, region, and environment in separate Terraform templates in separate folders is for 
**isolation**. This reduces the chances that when you're fiddling in, say, the staging environment in `us-west-2`, you 
accidentally break something in the prod environment in `us-east-1`. In fact, our setup also ensures that Terraform 
will store the [state of your infrastructure](https://www.terraform.io/docs/state/) in separate files for each 
environment too, so in the (very rare) case that you totally corrupt your state in the stage environment, your prod 
environment should keep running just fine.

This is why we recommend the following golden rule: **ALWAYS TEST YOUR CHANGES IN STAGE FIRST**. It's safe, easy, and
it will save you a lot of time & pain.