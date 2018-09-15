# Running An App in the Dev Environment

Now that you have an idea of [what the architecture looks like](01-architecture-overview.md), [what's
deployed](02-whats-deployed.md), and [how the code is organized](03-how-code-is-organized.md), it's time to start running
some of that code on your own computer!

Here's what we'll cover:

* [Prerequisites](#prerequisites)
* [Checkout the code](#checkout-the-code)
* [Run the app](#run-the-app)
* [Change the code](#change-the-code)
* [Update the application configuration](#update-the-application-configuration)
* [Encrypt a secret](#encrypt-a-secret)
* [Apply schema migrations](#apply-schema-migrations)
* [Commit your changes](#commit-your-changes)




## Prerequisites

You will need to install the following software on your computer:

* [Git](https://git-scm.com/): Used for version control.
* [Terraform](https://www.terraform.io/): Used to provision and manage infrastructure as code.
* [Terragrunt](https://github.com/gruntwork-io/terragrunt): A thin wrapper for Terraform that provides extra tools for 
  working with multiple Terraform modules.
* [Packer](https://www.packer.io/): Used to package apps as Amazon Machine Images.
* [GruntKMS](https://github.com/gruntwork-io/gruntkms): Used to encrypt and decrypt secrets.




## Checkout the code

You will need to checkout the code for your app(s) using Git. For this tutorial, we are going to checkout 
[sample-app-frontend](https://github.com/Veeps-Hosting/sample-app-frontend), which is a sample app that's handy for 
demonstrating all the key concepts in this tutorial. 

To check this app out onto your computer, run:

```bash
git clone git@github.com:Veeps-Hosting/sample-app-frontend.git
```

Note that sample-app-frontend depends on another sample app called [sample-app-backend](https://github.com/Veeps-Hosting/sample-app-backend), 
so you may want to checkout that app too:

```bash
git clone git@github.com:Veeps-Hosting/sample-app-backend.git
```




## Run the app

sample-app-frontend is a simple [Node.js](https://nodejs.org/en/) app, but the ideas demonstrated work more or less
the same way in any language. To run the sample code, you'll need to [install Node.js](https://nodejs.org/en/download/),
and then run:
 
```bash
cd sample-app-frontend
npm install
node app/server.js
```

The app will boot up in under a second and you should be able to test it by going to 
https://localhost:3000/sample-app-frontend 
(note that in dev mode, we use self-signed certs, so you'll have to tell your browser
to ignore the security warning and accept the self-signed cert). 

Take a look at `app/index.js` to see the code. You should also see other endpoints in that file that you can try.




## Change the code

Make a change to the app code, such as modifying `app/index.js` or `app/index.html`.
Restart your Node.js app (hit `CTRL + C` and then run `node app/server.js` again) and refresh the page in the browser
to see your changes. Alternatively, you can use [nodemon](https://github.com/remy/nodemon) in dev mode, and it will
restart Node for you automatically every time you make a change.




## Update the application configuration

sample-app-frontend stores most of its configuration settings in files. The advantage of this is that the files are 
checked into version control (so you have a history of config changes) and are versioned and deployed with the app code 
itself (so you don't get a mismatch between app and config). 

* The files live in the `config` directory. 

* The names use the format `example-config-<environment>.json`, where `environment` is an environment name, such as 
  development, stage, or prod. Note that the same basic config approach shown here works with any file format and 
  naming convention; we only use JSON because it's easy to use with the sample Node.js app.

* In `app/server.js`, the app loads the proper config file for the current environment based on the environment 
  variable `VPC_NAME`.
  
* In dev, the `VPC_NAME` environment variable is blank, so the app uses the default value of `development`.

* In other environments (e.g., stage, prod) the `VPC_NAME` environment variable is set by Terraform.




## Encrypt a secret

Occasionally, you may need to encrypt some secret data. For example, you may want to store the password to your 
database in your app's configuration. Storing secrets in plain text anywhere, including version control, is a major 
security risk and should be avoided (see [Gruntwork Security Best Practices](https://docs.google.com/document/d/e/2PACX-1vTikva7hXPd2h1SSglJWhlW8W6qhMlZUxl0qQ9rUJ0OX22CQNeM-91w4lStRk9u2zQIn6lPejUbe-dl/pub)
for more info). A better way to handle this is to encrypt the secrets before putting them in version control and to 
have your app decrypt those secrets before it boots.
  
Managing encryption keys securely is very tricky, so we strongly recommend using [Amazon's Key Management Service 
(KMS)](https://aws.amazon.com/kms/): 

1. Create "master key" in KMS using the [kms-master-key 
   module](https://github.com/gruntwork-io/module-security/tree/master/modules/kms-master-key). Note that we've already 
   created one master key in each environment, so for most use cases, you should use those and not create any new ones. 
   You can see all available master keys in the [Encryption Keys page in 
   IAM](https://console.aws.amazon.com/iam/home?region=ap-southeast-2#/encryptionKeys/ap-southeast-2). 

1. Use the master key, along with [gruntkms](https://github.com/gruntwork-io/gruntkms), to encrypt and decrypt secrets 
   with a single CLI command.
 
For example, you could run `gruntkms` on your computer to encrypt a database password:
 
```bash
# A developer encrypts a plaintext secret
$ echo "super secret database password" | gruntkms encrypt --key-id "alias/cmk-stage" --aws-region "us-east-1"
kmscrypt::AQICAHhQYFj4xrlpRdnui/MrOlrIt+gSSrFxZay4ZMDMofceSwEXSzGkmBBWbG6==
```
 
You can now safely check the `kmscrypt::...` ciphertext into version control.

You can then give your apps access to the same KMS key via IAM permissions and configure your apps to decrypt the 
ciphertext using `gruntkms` just before booting:

```bash
# An app decrypts the ciphertext before booting
echo "kmscrypt::AQICAHhQYFj4xrlpRdnui/MrOlrIt+gSSrFxZay4ZMDMofceSwEXSzGkmBBWbG6==" | gruntkms decrypt --aws-region "us-east-1"
"super secret database password" 
```

Make sure to read through the [gruntkms docs](https://github.com/gruntwork-io/gruntkms) to learn how how the `kmscrypt::` 
prefix works and how to decrypt all secrets in a config file in a single command (see `bin/run-app.sh` in the sample 
apps for an example).

Note that, as your apps need end-to-end encryption, we have also created self-signed TLS certificates for your apps 
(if you're unfamiliar with TLS, [see here for a quick 
primer](https://github.com/gruntwork-io/module-security/tree/master/modules/tls-cert-private#background)). The CA, 
public key, and private key are all checked into version control into the `tls` folder so that they are versioned and
packaged with the app. Note that the private key is encrypted with KMS!




## Apply schema migrations

sample-app-backend contains example code of how to talk to a relational database. It also contains an example of how
to apply schema migrations to your database before the app boots. The idea is to version and package the schema 
migration code with the app code so that whenever you deploy a new version of the app, it always ensures the schema it
depends on is in place before booting.

Under the hood, the example code manages the schema migrations using simple `.sql` files (see the `sql` folder) and 
uses [Flyway](https://flywaydb.org/) to apply those migrations (see `bin/run-app.sh`). The same basic approach should
work with any other schema migration tool (e.g., [Luiqibase](http://www.liquibase.org/), 
[ActiveRecord](http://edgeguides.rubyonrails.org/active_record_migrations.html)) as long as that tool obtains a lock 
before applying schema changes (to ensure you only apply the schema changes once even if multiple copies of the app
boot up at the same time).




## Commit your changes

If you've made any changes to the code during this tutorial, it's time to commit them back to Git!

```bash
git add <files_you_modified>
git commit -m "<commit message>"
git push origin master
```




## Next steps

Now that you've committed some code, it's time to learn how the automated [Build, test, and deployment 
(CI/CD)](05-ci-cd.md) process works.