# Deploying the Reference Architecture from scratch

This document is a guide to how to deploy the entire Reference Architecture, or one of the environments in the
Reference Architecture (e.g., stage or prod), from scratch. This is useful if you want to know how to quickly set up
and tear down environments.

1. [Build AMIs](#build-amis)
1. [Build Docker images](#build-docker-images)
1. [Build lambda functions](#build-lambda-functions)
1. [Create EC2 Key Pairs](#create-ec2-key-pairs)
1. [Configure Terraform backends](#configure-terraform-backends)
1. [Configure the VPN server](#configure-the-vpn-server)
1. [Create data store passwords](#create-data-store-passwords)
1. [Import Route 53 hosted zones](#import-route-53-hosted-zones)
1. [Create TLS certs](#create-tls-certs)
1. [Create an IAM User for KMS](#create-an-iam-user-for-kms)
1. [Run Terragrunt](#run-terragrunt)




## Build AMIs


All the EC2 Instances in the Reference Architecture (e.g., the ECS Cluster instances, the OpenVPN server, etc) run
[Amazon Machine Images (AMIs)](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) that are defined as code
using [Packer](https://www.packer.io/). You will find the Packer templates (`.json` files) in the
`infrastructure-modules` repo. You will also find that the corresponding Terraform modules (e.g, the `ecs-cluster`
module) expect an `ami_id` parameter to be set in `terraform.tfvars`.


### Running Packer

1. Authenticate to the AWS account. See [Accounts and Auth](08-accounts-and-auth.md).
1. Run `packer build <PATH-TO-TEMPLATE>`. E.g., `packer build infrastructure-modules/services/ecs-cluster/packer/ecs-node.json`.
1. At the end of the build, Packer will output the new AMI ID. You can use this in the `ami_id` parameter of
   `terraform.tfvars` files.


### AMIs and AWS regions

Note that AMIs live in a specific AWS region, so if you're deploying to multiple regions, you will have to build AMIs
for each region separately. If this is a common task, you can specify multiple `builders` in the Packer template, one
for each region, and the builds will run in parallel.


### Sharing AMIs across AWS accounts

You can share AMIs across AWS accounts to avoid having to rebuild the same AMI over and over again. For example, you
could build the ECS AMI once in the shared-services account and deploy that same AMI in dev, stage, and prod. To enable
this, set the `ami_users` parameter to the IDs of the accounts that should have access to the AMI. For example, to
give accounts `11111111111` and `22222222222` access to an AMI:

```json
{
  "builders": [{
    "type": "amazon_ebs",
    "ami_users": ["11111111111", "22222222222"]
  }]
}
```


### AMIs and encryption

If you want to encrypt the root volume of your EC2 Instances (e.g., for end-to-end encryption and compliance purposes),
you will need to set the `encrypt_boot` parameter to true in the Packer template:

```json
{
  "builders": [{
    "type": "amazon_ebs",
    "encrypt_boot": true
  }]
}
```

Note that encrypted AMIs may **NOT** be shared with other AWS accounts!




## Build Docker images

If you're using Docker, the sample apps in the Reference Architecture will try to deploy Docker images. You will need
to:

1. Build the Docker images
1. Tag them with a version number of some sort
1. Push the images to your Docker Registry (typically [ECR](https://aws.amazon.com/ecr/))
1. Fill in the Docker image name and version number in the `terraform.tfvars` files in `infrastructure-live`

The instructions for building, tagging, and pushing the Docker images are in the READMEs of the
[sample-app-frontend](https://github.com/Veeps-Hosting/sample-app-frontend) and
[sample-app-backend](https://github.com/Veeps-Hosting/sample-app-backend) repos.




## Build lambda functions

The Reference Architecture include several sample [Lambda functions](https://aws.amazon.com/lambda/) under
`infrastructure-modules/lambda`. These show examples of how to use Lambda to perform various tasks without having to
manage any servers.

One of the Lambda functions in `infrastructure-modules/lambda` requires an extra build step to create its
[deployment package](https://docs.aws.amazon.com/lambda/latest/dg/deployment-package-v2.html) before you can deploy it:

```bash
./infrastructure-modules/lambda/long-running-scheduled/src/build.sh
```

At the end of that script, it will output the path of the resulting deployment package, plus instructions on how to use
this path, which will tell you to set an environment variable. Make sure to follow those instructions!



## Create EC2 Key Pairs

The Reference Architecture installs [ssh-grunt](https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt)
on every EC2 Instance so that each developer can use their own username and key to SSH to servers
(see [SSH and VPN](07-ssh-vpn.md)). However, we still recommend associating an [EC2 Key
Pair](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) with your EC2 Instances as an emergency
backup, in case their is some sort of issue with `ssh-grunt`.

We typically recommend creating at least 2 Key Pairs:

1. For the OpenVPN server.
1. For all other services.

To create an EC2 Key Pair:

1. Go to the [Key Pair section](https://console.aws.amazon.com/ec2/v2/home#KeyPairs:sort=keyName) of the EC2 Console.
1. Click "Create Key Pair."
1. Enter a name for the Key Pair.
1. Save the Key Pair to disk. Do NOT share this Key Pair with anyone else; it's only for emergency backup!
1. Add a passphrase to the Key Pair: `ssh-keygen -p -f <KEY_PAIR_PATH>`.
1. Change permissions on the Key Pair: `chmod 400 <KEY_PAIR_PATH>`.
1. Pass the Key Pair name to the appropriate parameter in `terraform.tfvars` in `infrastructure-live`; typically, this
   parameter will be called `ssh_key_name`, `keypair_name`, or `cluster_instance_keypair_name`. Ensure you only use
   the OpenVPN keypair for the OpenVPN server.




## Configure Terraform backends

The Reference Architecture uses an [S3 backend](https://www.terraform.io/docs/backends/types/s3.html) to store
[Terraform State](https://www.terraform.io/docs/state/). We also use DynamoDB for locking. We recommend storing the
Terraform State for each AWS account in a separate S3 bucket and DynamoDB table. You will need to fill in the name and
region of the S3 bucket and DynamoDB table in two places in the top-level folder for that account in
`infrastructure-live`:

1. `terraform.tfvars`
1. `account.tfvars`

When you run Terragrunt, if the S3 bucket or DynamoDB table don't already exist, they will be created automatically.




## Configure the VPN server

The Reference Architecture includes an [OpenVPN server](https://openvpn.net/). The very first time you deploy the
server, it will create the [Public Key Infrastructure (PKI)](https://en.wikipedia.org/wiki/Public_key_infrastructure) it will
use to sign certificates. This process is very CPU intensive and, on `t2.micro` EC2 Instances, it can take *hours*, as
it seems to exceed the burst balance almost immediately.

To avoid this, we recommend initially deploying the OpenVPN server with a larger instance (`t2.medium` can generate the
PKI in 1-2 minutes). Once the PKI has been generated, you can downgrade to a smaller instance again to save money.




## Create data store passwords

Some of the data stores used in the Reference Architecture, such as [RDS databases](https://aws.amazon.com/rds/),
require that you set a password in the Terraform code. We do NOT recommend putting that password, in plaintext,
directly in the code. Instead, we recommend:

1. Create a long, strong, random password. Preferably 30+ characters.
1. Store the password in a secure secrets manager.
1. Every time you go to deploy the data store, set the password as an environment variable that Terraform can find
   (see [Terraform environment variables](https://www.terraform.io/docs/configuration/variables.html#environment-variables)).
   For example, for RDS DBs, you typically set the `TF_VAR_master_password` environment variable:

    ```bash
    export TF_VAR_master_password=(...)
    ```




## Import Route 53 hosted zones

The Reference Architecture configures DNS entries using [Route 53](https://aws.amazon.com/route53/). Each domain name
will live in a [Public Hosted Zone](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/AboutHZWorkingWith.html)
that is either created automatically if you bought a domain name through Route 53, or manually if you are using Route
53 to manage DNS for a domain name bought externally.

If the Public Hosted Zone already exists, you will need to use the [import
command](https://www.terraform.io/docs/import/index.html) to put it under Terraform control. Go to the `route53-public`
module in `infrastructure-live` for the account you're deploying and run:

```bash
terragrunt import aws_route53_zone.primary_domain <HOSTED_ZONE_ID>
```

Where `HOSTED_ZONE_ID` is the primary ID of your Hosted Zone, which you can find in the AWS Console (it typically looks
something like `Z1AB1Z2CDE3FG4`).




## Create an IAM User for KMS

The Reference Architecture uses [KMS](https://aws.amazon.com/kms/) to encrypt and decrypt secrets. When you create a
new [Customer Master Key (CMK)](https://docs.aws.amazon.com/kms/latest/developerguide/concepts.html) in KMS, you must
assign at least one IAM User as an "administrator" for the CMK. If there are no admins, then the CMK—and any secrets
encrypted with it—may become completely inaccessible!

Therefore, you will need to create an IAM User, either in the same AWS account (for single-account deploymens) or in
the security account (for multi-account deployments), and provide that IAM Users ARN to the
`cmk_administrator_iam_arns` parameter of the `kms-master-key` module.




## Create TLS certs


### Public-facing TLS certs

The Reference Architecture will automatically use TLS certs from the [AWS Certificate Manager
(ACM)](https://aws.amazon.com/certificate-manager/) with each of your public load balancers (`networking/alb-public` in
`infrastructure-live`) and CloudFront distributions (`services/static-website` in `infrastructure-live`). If you are
deploying with totally new domain names, you will need to:

1. [Request a certificate from ACM](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html) for the
   AWS region(s) you are deploying to. The Terraform modules in the Reference Architecture typically look for a
   wildcard certificate of the format `*.<your-domain-name>` (e.g., `*.acme.com`), so make sure to request a wildcard
   certificate. If you don't want to use wild card certs, update the code in `infrastructure-live` and
   `infrastructure-modules` accordingly.
1. If this is a certificate for a domain name managed in Route 53, we recommend [using DNS to validate domain
   ownership](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-validate-dns.html), as it only takes a couple
   clicks.
1. If you are using CloudFront, you **must** also request a certificate for `us-east-1`, no matter what region you are
   deploying too. See the [cloudfront module](https://github.com/gruntwork-io/package-static-assets/tree/master/modules/s3-cloudfront)
   for more info.


### Self-signed TLS certs for your apps

If you want to use end-to-end encryption, you will need to generate self-signed TLS certs for your apps so that other
apps or the load balancer can send traffic to them over TLS. If you are unfamiliar with how TLS certificates work,
start with the [Background
documentation](https://github.com/gruntwork-io/module-security/tree/master/modules/tls-cert-private#background).

There are many ways to generate a certificate and use it with your apps, but the easiest option is:

1. Use the [private-tls-cert module](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/private-tls-cert)
   to generate the certificates. If you are using an ELB or ALB, then you can use any IP addresses or DNS names you
   wish, as the AWS load balancers will not check. If you are using service discovery (e.g., [ECS Service
   Discovery](https://github.com/gruntwork-io/module-ecs/tree/master/modules/ecs-service-with-discovery)), you will
   need to generate the TLS cert with the same domain name you are going to use for service discovery. In either case,
   you may want to include `127.0.0.1` and `localhost` in the cert to make local testing easier. This should give you
   back a public and private key for the TLS certificate and a public key for the CA.

1. Encrypt the private key using [gruntkms](https://github.com/gruntwork-io/gruntkms) with the KMS master key for the
   appropriate environment.

1. Package the public and encrypted private key of the TLS cert with the app (e.g., update your `Dockerfile` or Packer
   template to package the TLS cert).

1. Use `gruntkms` to decrypt the private key just before the app boots (the `run-app.sh` script already does this).

1. During boot, configure your app to load the public and private key of the TLS cert and listen for TLS connections.
   How you do this is app-specific.

1. If you have other apps that are going to talk to your app directly (e.g., via service discovery), distribute the
   public key of the CA to those apps so they can validate your app's cert.


### Self-signed TLS certs for your internal load balancers

If you want to use end-to-end encryption, you will need to generate self-signed TLS certs for your internal load
balancers so that your apps can send requests to those load balancers over TLS. If you are unfamiliar with how TLS
certificates work, start with the [Background
documentation](https://github.com/gruntwork-io/module-security/tree/master/modules/tls-cert-private#background).

There are many ways to generate a certificate and use it with a load balancer, but the easiest option is:

1. Use the [private-tls-cert module](https://github.com/hashicorp/terraform-aws-vault/tree/master/modules/private-tls-cert)
   to generate the certificates. Configure the TLS cert with a domain name you are going to be using for your load
   balancer (see the next steps for how this domain name will work). This should give you back a public and private key
   for the TLS certificate and a public key for the CA.

1. Create an internal domain name (e.g., `veeps-hosting.internal`) using [Route 53 Private
   Hosted Zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-private.html). This domain name
   should match the one in the TLS certificate you created. See `networking/route53-private` in
   `infrastructure-live`.

1. Import your certificate into the AWS Certificate Manager (ACM). One way to do this is with the `aws` CLI
   [import-certificate command](https://docs.aws.amazon.com/cli/latest/reference/acm/import-certificate.html), passing
   it the public key of the certificate using the `--certificate` argument, the private key via the `--private-key`
   argument, and the CA's public key using the `--certificate-chain` argument:

    ```
    aws acm import-certificate \
      --region us-east-1 \
      --certificate file://cert.pem \
      --private-key file://cert.key \
      --certificate-chain file://ca.pem
    ```

   You'll need to do this in each region where you're going to deploy a load balancer. Once you've imported the
   certificate everywhere, you may want to delete the private key so no one else can access it. If you're going to keep
   the private key around, then make sure to use [gruntkms](https://github.com/gruntwork-io/gruntkms) to encrypt it
   with KMS.

1. Create your load balancer with an HTTPS listener and set the certificate ARN to the ARN of the certificate you just
   imported into ACM. You can find the ARN automatically using the [aws_acm_certificate data
   source](https://www.terraform.io/docs/providers/aws/d/acm_certificate.html).

1. Create a Route 53 A Record that points at your load balancer with the domain name and Private Hosted Zone you
   created in step 2. You can use the [aws_route53_record
   resource](https://www.terraform.io/docs/providers/aws/r/route53_record.html) to create the record and find the
   Hosted Zone ID of your Private Hosted Zone automatically using the [aws_route53_zone data
   source](https://www.terraform.io/docs/providers/aws/d/route53_zone.html).

1. You'll want to distribute the public key of the CA to any app that is going to talk to your load balancer so that it
   can use it to validate the TLS certificate.



## Run Terragrunt

Now that you have all the prerequisites out of the way, you can finally use Terragrunt to deploy everything!


### Authenticate

If you're creating a  totally new AWS account, the easiest way to do the initial deployment is to [create a temporary IAM
User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) in that account with admin access. Create
[Access Keys](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html) for that IAM User and
set them as environment variables:

```bash
export AWS_ACCESS_KEY_ID=(your access key for this account)
export AWS_SECRET_ACCESS_KEY=(your secret key for this account)
```

Once everything is deployed, you can delete this IAM user, and access the account via IAM roles (see the
[cross-account-iam-access module](https://github.com/gruntwork-io/module-security/tree/master/modules/cross-account-iam-roles)
for details).

If you're using an AWS account that already exists and has already been configured with cross-account IAM roles as part
of the multi-account Reference Architecture setup, you should set environment variables for the **security** account:

```bash
export AWS_ACCESS_KEY_ID=(your access key for the security account)
export AWS_SECRET_ACCESS_KEY=(your secret key for the security account)
```

You should then set the `TERRAGRUNT_IAM_ROLE` to the ARN of an IAM role in the account you're deploying to that will
give you administrative access. Typically, you'll want the `allow-full-access-from-other-accounts` IAM role:

```bash
export TERRAGRUNT_IAM_ROLE="arn:aws:iam::<ACCOUNT_ID>:role/allow-full-access-from-other-accounts"
```


### Run apply-all

To deploy the entire account in a single command, you can use `apply-all`. For example, to deploy the stage account:

```bash
cd infrastructure-live/stage
terragrunt apply-all
```

You may want to run Terragrunt with the `--terragrunt-non-interactive` flag to avoid any interactive prompts:

```bash
terragrunt apply-all \
  --terragrunt-non-interactive
```

If you want to deploy code from your local checkout of `infrastructure-modules`, rather than a versioned release, use
the `--terragrunt-source` parameter:

```bash
terragrunt apply-all \
  --terragrunt-non-interactive \
  --terragrunt-source ../../infrastructure-modules
```

If you want to deploy just a single module at a time, just use `terragrunt apply`:

```bash
cd infrastructure-live/stage/us-east-1/stage/services/ecs-cluster
terragrunt apply
```


### Deployment order

Note that, in general, there are no dependencies between different AWS accounts, so you can deploy them in any order.
The only exception to this is the `security` account in the multi-account setup. This account defines all IAM Users,
Groups, and the S3 bucket used for CloudTrail audit logs, so it must always be deployed first.

Within an AWS account, there are many deployment dependencies (e.g., almost everything depends on the VPC being
deployed first), all of which should be defined in the `dependencies` blocks of `terraform.tfvars` files. Terragrunt
takes these dependencies into account automatically and should deploy everything in the right order.




### Expected errors

Due to bugs in Terraform, you will most likely hit some of the following (harmless) errors:

1. TLS handshake timeouts downloading Terraform providers or remote state. See
   https://github.com/hashicorp/terraform/issues/15817.

1. "A separate request to update this alarm is in progress". See
   https://github.com/terraform-providers/terraform-provider-aws/issues/422.

1. "Error loading modules: module xxx: not found, may need to run 'terraform init'". This typically happens if you
   run `apply-all`, change the version of a module you're using, and run `apply-all` again. Unfortunately, Terragrunt
   is not yet smart enough to automatically download the updated module (see
   https://github.com/gruntwork-io/terragrunt/issues/388). Easiest workaround for now is to set
   `TERRAGRUNT_SOURCE_UPDATE=true` to force Terragrunt to redownload everything:

    ```bash
    TERRAGRUNT_SOURCE_UPDATE=true terragrunt apply-all
    ```

If you hit any of these issues—and you'll almost certainly hit one of the first two—simply re-run `apply-all` and they
should go away.
