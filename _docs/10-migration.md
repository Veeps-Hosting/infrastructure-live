# Migration

Now that you understand how the Reference Architecture works, the next step is to begin migrating your apps to it. The
process we recommend is as follows:

1. [Do the migration incrementally](#do-the-migration-incrementally)
1. [Set up account access](#set-up-account-access)
1. [Deploy your apps](#deploy-your-apps)
1. [Migrate your data stores](#migrate-your-data-stores)
1. [Configure monitoring and alerting](#configure-monitoring-and-alerting)
1. [Test](#test)
1. [Switch over DNS](#switch-over-dns)




## Do the migration incrementally

Most "big bang" migrations—where you try to pick up everything and move it over to a new cloud (AWS), new tools
(Terraform, Docker, Packer), and new processes (CI, CD, DevOps), all in one huge step—almost always fail. The only way
to succeed at a big migration is to do it *incrementally*. Note that "incrementally" doesn't mean you just chop up the
work into small parts; it means you chop it up into small parts so that *each part is worth doing, even if the other
parts never happen*.

If the only value you get from the migration is at the very end of a long process (and lets be honest, migrations
*always* take longer than you expect), then there's a good chance management will lose patience, developers will get
frustrated, funding for the project will be cut, corners will be cut, and the project will be a disaster.

Therefore, you want to arrange the work so that you can complete one small piece at a time and get value out of that
piece immediately. That way, management stays happy, developers stay motivated, and the project is worth doing, even
if the end of the migration is still a long ways off.

You'll find a number of suggestions in this document on how to do the migration incrementally. The short version is:

1. Migrate one or a small number of apps.
1. Allow the apps to keep using the data stores and other dependencies in your original data center via a VPN
   connection.
1. Test.
1. Once things are working, switch over the DNS config to point to the apps running in AWS.
1. Repeat the previous steps with the rest of your apps.
1. Once all apps have been migrated, begin migrating your data stores.

Read on for the long version!




## Set up account access

The first step to migrating to the Reference Architecture is to make sure everyone on your team has access to your AWS
accounts. This consists of the following items:

1. [Security primer](#security-primer)
1. [Root user](#root-user)
1. [IAM users](#iam-users)
1. [IAM groups](#iam-groups)
1. [SSH access](#ssh-access)


### Security primer

We **strongly** recommend that everyone on your team reads through the following:

1. [Gruntwork Security Best
   Practices](https://docs.google.com/document/u/1/d/e/2PACX-1vTikva7hXPd2h1SSglJWhlW8W6qhMlZUxl0qQ9rUJ0OX22CQNeM-91w4lStRk9u2zQIn6lPejUbe-dl/pub),
   doc, which covers critical concepts such as how to securely store secrets, how to lock down servers, and how to
   securely use AWS.
1. [A Comprehensive Guide to Authenticating to AWS on the Command
   Line](https://blog.gruntwork.io/a-comprehensive-guide-to-authenticating-to-aws-on-the-command-line-63656a686799),
   which covers all the basics of AWS auth, including all the different options for how to authenticate on the CLI.



### Root user

Each of your AWS accounts has a [root user](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user.html). Whoever
created the account should have access to the root user. If you created the account using the [gruntwork
CLI](https://github.com/gruntwork-io/gruntwork) or [AWS Organizations](https://aws.amazon.com/organizations/), then
you will know the email address associated with the root user, but not the password. To get the password:

1. Go to the [AWS Console](https://console.aws.amazon.com/console/home)
1. If you had previously signed into some other AWS account, click "Sign-in using root account credentials."
1. Enter the email address and click "Forgot your password" to reset the password.
1. Check the email address associated with the root user account for a link you can use to create a new password.

Please note that the root user account can do just about *anything* in your AWS account, bypassing almost all security
restrictions you put in place, so you need to take extra care with protecting this account. We **very strongly**
recommend that you:

1. Use a strong password. Preferably 30+ characters, randomly generated, and stored in a secrets manager.
1. [Enable Multi-Factor Auth](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa_enable_virtual.html#enable-virt-mfa-for-root)
   for the root user.
1. *Only* use the root user to create an IAM User for yourself and then switch to the IAM User for all other operations
   thereafter. You should NOT use the root user account on a day-to-day basis; it's there only for very rare
   circumstances (e.g., if you get locked out of your IAM User account).


### IAM users

You should create an [IAM User](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html) for each
developer. The Reference Architecture enforces a
[password policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_passwords_account-policy.html): see
the `iam-user-password-policy` module in `infrastructure-live` for the details. We also **strongly** recommend
requiring every developer to [enable multi-factor auth](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_mfa.html)
for their IAM users.


### IAM groups

Give each IAM User permissions by adding them to the appropriate [IAM
Groups](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_groups.html). The following IAM Groups may be of especial
interest (see the [iam-groups](https://github.com/gruntwork-io/module-security/tree/master/modules/iam-groups) module
for a more complete list):

1. **full-access**: This gives full admin privileges within this AWS account. Use this only for a small number of
   trusted admins.
1. **read-only**: This gives read-only access within this AWS account. This is especially useful for production
   accounts where you want to be able to debug, but not necessarily make changes.
1. **openvpn-users**: This allows users to use [openvpn-admin](https://github.com/gruntwork-io/package-openvpn/tree/master/modules/openvpn-admin)
   to request VPN certificates in this AWS account. See [SSH and VPN](07-ssh-vpn.md) for more info.
1. **ssh-grunt-users**: Users in this group will be able to access servers via SSH. See [SSH and VPN](07-ssh-vpn.md) for
   more info.
1. **ssh-grunt-sudo-users**: Users in this group will be able to access servers via SSH with sudo permissions. See
   [SSH and VPN](07-ssh-vpn.md) for more info.


### SSH Access

We have configured [ssh-grunt](https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt) on every
EC2 Instance, so developers will be able to SSH to the servers using their own usernames and SSH keys. See
[SSH and VPN](07-ssh-vpn.md) for instructions.




## Deploy your apps

Once account access is set up, the next step is to migrate your apps—or even just a single app—to the Reference
Architecture, while continuing to use whatever data stores and other dependencies you already have deployed in your old
data center (e.g., via a VPN connection). Once you can get one app running in AWS successfully, you can use it as a
template to move over the others, getting value from the migration right away (i.e., more security, scalability, etc)
without having to wait weeks or months to move everything over (incrementalism!).

To move over an app, you'll need to do the steps listed below. The Reference Architecture includes two sample apps
(`sample-app-frontend` and `sample-app-backend`) that show how to implement all of these steps, so use them as a
reference!

Note that you do NOT need to do all of these steps at once! You can take care of just a few of them, deploy the app
into the Reference Architecture, see that some basic things work, move on to the next few steps, and so on.

1. [Package the app](#package-the-app)
1. [Add a health check endpoint](#add-a-health-check-endpoint)
1. [Update the load balancer config](#update-the-load-balancer-config)
1. [Set up config files for each environment](#set-up-config-files-for-each-environment)
1. [Encrypt secrets](#encrypt-secrets)
1. [Configure schema migrations](#configure-schema-migrations)
1. [Configure service discovery](#configure-service-discovery)
1. [Set up static content](#set-up-static-content)
1. [Configure CI and CD](#configure-ci-and-cd)


### Package the app

To deploy into the Reference Architecture, you will need to package your app using one of the following tools:

1. [Packer](https://www.packer.io/): If you are deploying your apps directly on EC2 Instances, use Packer to package
   your apps as [Amazon Machine Images](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html).

1. [Docker](https://www.docker.com/): If you are deploying your apps as Docker containers, create a `Dockerfile` to
   package your app as a Docker image.

See the [sample-app-frontend](https://github.com/Veeps-Hosting/sample-app-frontend) and
[sample-app-backend](https://github.com/Veeps-Hosting/sample-app-backend) repos for examples.


### Add a health check endpoint

Each app should expose a health check endpoint (e.g., `/health`) that the load balancer can use to see if the app is
running and ready to receive requests. The health check endpoint should return a `200 OK` when the app is healthy.
The definition of "healthy" depends on the app; for some apps, healthy might mean the app has booted; for others,
healthy may mean the app has booted, can talk to databases, and has warmed up its cache.


### Update the load balancer config

Now that your app is packaged and has a health check endpoint, you can try deploying it! The sample apps are deployed
via Terraform code in the `infrastructure-live` repo, under the `services` folder (e.g.,
`stage/services/sample-app-frontend`). Make a copy of that folder and customize the `terraform.tfvars` file within it
to deploy your app instead. This will include specifying which paths in the load balancer your app should claim.

This is because the Reference Architecture uses a single [Application Load Balancer
(ALB)](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) for several apps in
each environment, and each of those apps can claim certain paths (e.g., `/foo` goes to app foo, `/bar` goes to app bar)
and/or certain domain names (e.g., `foo.acme.com` goes to app foo, `bar.acme.com` goes to app bar). If you want your
app to handle all paths, you can use regular expressions (e.g., `*`).


### Set up config files for each environment

If your app needs to be configured differently in each environment (e.g., in stage and prod), we recommend creating
config files for each environment, checking those configs into version control, and packaging them with the app. That
way, config is updated, versioned, tested, and deployed exactly like the rest of your code. This tends to be easier
to reason about and far less error prone than storing configs externally (e.g., in a DB).

The sample apps use JSON files for config, but any format supported by your apps will be fine, so long as it is
file-based. See the `config` folder in the sample apps for an example, and check out the `bin/run-app.sh` script for
how the sample apps select the proper config file for the current environment.


### Encrypt secrets

If your apps need access to secrets, such as the password to a database, we recommend encrypting those secrets with
[KMS](https://aws.amazon.com/kms/) and adding the ciphertext to your config files. Your apps can then use IAM Roles to
decrypt the secrets just before booting.

See [encrypt a secret](04-dev-environment.md#encrypt-a-secret) for instructions.


### Configure schema migrations

If your apps talk to a relational database, you will need a way to evolve the database schema over time. The best way
to do that is to use a schema migration tool such as [Flyway](https://flywaydb.org/) or
[Liquibase](https://www.liquibase.org/) to define the schema migrations as code, check that code into version control,
package it with your apps, and have your apps apply the schema migrations just before booting (Flyway and Liquibase
will use locks to ensure there are no concurrency issues).

See the `sql` folder and `bin/run-app.sh` of `sample-app-backend` for an example.


### Configure service discovery

If you need to run multiple apps ("microservices") that talk to each other, those apps will need a way to discover each
other's IP and port. In the dynamic world of AWS, IPs and ports change all the time, so you don't want to hard code
them. Instead, use one of the following options:

1. Use an internal load balancer. Each of your apps can register at a different path with the load balancer, and each
   app gets the load balancer domain name as an environment variable (via Terraform), so, for example, you can talk to
   app `foo` by sending a request to `<LOAD_BALANCER_DOMAIN_NAME>/foo` and to app `bar` by sending a request to
   `<LOAD_BALANCER_DOMAIN_NAME>/bar`. This is how `sample-app-frontend` talks to `sample-app-backend`.

1. For Docker containers running in ECS, you can use [ECS Service
   Discovery](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/service-discovery.html). As of May, 2018,
   Gruntwork has not yet added support for this, but it should be added to the [ECS
   modules](https://github.com/gruntwork-io/module-ecs/) soon.

1. Use a tool such as [Consul](https://www.consul.io/). This does require running extra infrastructure, which is made
   easier via the Gruntwork [Consul module](https://github.com/hashicorp/terraform-aws-consul) (not currently part of
   the Reference Architecture).


### Set up static content

The best way to serve CSS, JS, images, and fonts is by putting them in an [S3 bucket](https://aws.amazon.com/s3/) and
using [CloudFront](https://aws.amazon.com/cloudfront/) as a CDN in front of it. Your Reference Architecture may already
contain an example of this under the `services/static-website` folder. Your CloudFront distribution will have its own
domain name (e.g., `static.<your-company>.com`), so you'll need to ensure that any code of yours that links to static
content (e.g., server-side rendered HTML) makes it possible to configure a different static content domain name in
each environment.


### Configure CI and CD

The sample apps have Continuous Integration (CI) and Continuous Delivery (CD) configured for them. A CI job will run
after every commit to build, test, and package the apps, and, for certain commits (e.g., to specific branches or with
specific tags), the CI job will automatically deploy the app to stage or prod.

See [Build, tests, and deployment (CI/CD)](05-ci-cd.md) and the sample app repos for details on how to set up the same
CI/CD workflow for your real apps.




## Migrate your data stores

Once you have your apps running in AWS, the next step is to migrate the data stores they depend on. We again recommend
doing this incrementally, moving over one data store at a time, if possible. There are two ways to move over your data
stores:

1. Take a downtime
1. Do a zero-downtime migration

Option #2 typically takes 100x longer (this is NOT an exaggeration) than option #1 and has a much higher risk of
data loss or data corruption. If at all possible, we **very strongly** recommend taking a brief downtime to do the
migration, as it will make your life much easier.

A few guidelines about migrating data stores:

1. [Migrating from another AWS-managed data store](#migrating-from-another-aws-managed-data-store)
1. [Migrating from external data stores](#migrating-from-external-data-stores)
1. [If you absolutely must do a zero-downtime migration](#if-you-absolutely-must-do-a-zero-downtime-migration)


### Migrating from another AWS-managed data store

If you are migrating to the Reference Architecture from another AWS account, and in that account you are using an
AWS-managed data store such as [RDS](https://aws.amazon.com/rds/) or [ElastiCache](https://aws.amazon.com/elasticache/),
the migration process (with downtime!) is:

1. Put your app in read-only mode or take a downtime.
1. Use the built-in snapshotting mechanism to take a snapshot of the data store (e.g., [RDS
   snapshots](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CreateSnapshot.html) or
   [ElastiCache snapshots](https://docs.aws.amazon.com/AmazonElastiCache/latest/APIReference/API_Snapshot.html)).
1. Share the snapshot with the prod account where the Reference Architecture is deployed (e.g., see [Sharing a DB
   Snapshot](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ShareSnapshot.html)).
1. Deploy a new data store in the Reference Architecture account from the snapshot (e.g., set the
   `snapshot_identifier` parameter in the [rds module](https://github.com/gruntwork-io/module-data-storage/tree/master/modules/rds)).
1. Bring your app back up.


### Migrating from external data stores

If you are migrating data stores from non-AWS managed systems (e.g., from your own data center), the process is the
same as in the previous section, except instead of using the snapshotting mechanism built into AWS, you will need to
use one of these mechanisms instead:

1. Use the [AWS database migration service](https://aws.amazon.com/dms/) to migrate relational databases.
1. Use a mechanism supported by RDS and your database, such as [restoring MySQL into RDS using Percona
   XtraBackup](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/MySQL.Procedural.Importing.html).
1. Use your data store's native snapshot functionality (e.g., [mysqldump](https://dev.mysql.com/doc/refman/5.5/en/mysqldump.html))
   to make a backup of your database, copy the backup into AWS (e.g., into an S3 bucket), and fire up an EC2 Instance
   that connects to the data store and loads the backup into it.

Note that all of these assume at least some amount of downtime!


### If you absolutely must do a zero-downtime migration

If you absolutely cannot take any downtime whatsoever (unlikely, as you most likely have unplanned outages anyway!),
things get a lot more complicated. The typical strategy is:

1. Take an initial snapshot of your data store and load it into AWS. The idea is to move most of the data over early on
   and then "catch up" whatever new data is written in the following steps.
1. Find a way to send all new writes to both your original data store and the new one in AWS.
1. Once the new data store has "caught up", start using it directly instead of the old database.

Step #2 is the tricky one, as dual writes are notoriously error prone. For example, what happens if the process doing
dual writes succeeds with the first write, but crashes before the second? What if it sends the requests to both data
stores, but one of them is temporarily down? What if both requests make it to the data stores, but then a transaction
gets rolled back? See [why dual writes are a bad
idea](https://www.confluent.io/blog/using-logs-to-build-a-solid-data-infrastructure-or-why-dual-writes-are-a-bad-idea/)
for more info.

The most common solutions to these problems are:

1. Use a change capture system. This is a system that effectively replicates your data store's underlying log: you
   write to the original data store, and if this write has succeeded and been committed, it triggers an "event" in the
   change capture system, which an event processor then writes to the second data store. For example,
   see [databus](https://github.com/linkedin/databus) and [bottledwater-pg](https://github.com/confluentinc/bottledwater-pg).

1. Send all writes initially to a log system such as [Apache Kafka](https://kafka.apache.org/). You then have one
   Kafka consumer that writes the messages to your original data store and another that writes it to the new data store.
   Kafka guarantees at-least once delivery, so as long as the database writes are idempotent, this ensures no data
   will be lost.

Whatever option you go with, we strongly recommend adding "integrity checking" to verify no data was lost or corrupted.
Some example integrity checks:

1. Count the number of rows in each table and make sure they are identical in both data stores.
1. Perform a checksum or hash on all the data in a table (or some randomly selected subset if there's too much data)
   and make sure you get identical values in both data stores.




## Configure monitoring and alerting

Once your apps and data stores are working, you'll want to make sure you have the following monitoring and alerting in
place:

1. [Metrics](#metrics)
1. [Alerts](#alerts)
1. [Logs](#logs)


### Metrics

Make sure all the metrics you expect show up in [CloudWatch](https://aws.amazon.com/cloudwatch/). All AWS services
automatically send metrics to CloudWatch and the Reference Architecture includes a few important ones that are not
available by default (e.g., memory and disk space usage on EC2 Instances). Create
[Dashboards](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Dashboards.html) for the
most important metrics, such as CPU usage in your ECS cluster or request count in the ALB.

Note that the Reference Architecture uses CloudWatch for metrics as it's built-into AWS, very inexpensive, and requires
very little work to maintain. However, the CloudWatch UI is fairly basic, so if you need more powerful tools for slicing
and dicing your metrics, consider tools such as [DataDog](https://www.datadoghq.com/),
[New Relic](https://newrelic.com/), or [Prometheus](https://prometheus.io/). If you'd like help with this, please reach
out to support@gruntwork.io.


### Alerts

Configure alerts to go off for key metrics. All the services in the Reference Architecture have basic alarms
configured directly in the Terraform code, such as low disk space alarms on RDS DBs and high CPU usage alarms for the
ECS cluster. All of the Terraform modules allow you to tweak the settings for these alarms (e.g., should the CPU
usage alarm go off at 80% or 90%?), so take some time to go through each module in `infrastructure-modules` and
make sure the settings match your use cases so you don't have too many false positives or negatives.


### Logs

The logs from all servers get automatically sent to [CloudWatch
Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html). The  `user-data.sh` scripts
in `infrastructure-modules` call `run-cloudwatch-logs-agent.sh` (from the [cloudwatch-log-aggregation-scripts
module](https://github.com/gruntwork-io/module-aws-monitoring/tree/master/modules/logs/cloudwatch-log-aggregation-scripts))
to configure which log files get sent to CloudWatch. By default, `syslog` is sent to CloudWatch on every server, and
ECS Services are configured to send their logs to `syslog`. Make sure you can find the logs for your apps there
*before* you go live!

Note that the Reference Architecture uses CloudWatch Logs as it's built-into AWS, very inexpensive, and requires
very little work to maintain. However, the CloudWatch UI is fairly basic, so if you need more powerful tools for slicing
and dicing your log data, consider tools such as [ELK](https://www.elastic.co/elk-stack) (as of May, 2018, the ELK
support is under development in the [package-elk](https://github.com/gruntwork-io/package-elk/) repo and should be
ready soon), [Loggly](https://www.loggly.com/), and [Papertrail](https://papertrailapp.com/). If you'd like help with
this, please reach out to support@gruntwork.io.





## Test

As you go through the process of migrating your apps and data stores, you should continuously be testing your
infrastructure to make sure things are working. Here are the key types of tests to perform:

1. **Manual testing**: Hit URLs by hand, look at log files, and check the metrics. You already know how to do this!

1. **Automated testing**: We strongly recommend writing automated tests that (a) deploy your infrastructure into an
   AWS account dedicated for testing, (b) check the infrastructure works as expected, and (c) tears the infrastructure
   back down at the end of the test. You can use the [Terratest](https://github.com/gruntwork-io/terratest) library
   to write these tests.

1. **Load testing**: You should make sure your code performs well under the kind of loads you expect in production.
   Use tools such as [Apache Bench](https://httpd.apache.org/docs/2.4/programs/ab.html),
   [JMeter](https://jmeter.apache.org/) to throw traffic at your infrastructure and when things fall over, make sure
   your monitoring and alerting can help you find the bottlenecks! Load testing across several different EC2 Instance
   Types can also be a good way to find the sweet spot between price and performance (see [How Netflix Tunes EC2
   Instances for Performance](https://www.slideshare.net/brendangregg/how-netflix-tunes-ec2-instances-for-performance)).

1. **Security testing**: Bring in an outside firm to pen test and audit your code to look for security vulnerabilities.
   Gruntwork customers have done this several times with the Reference Architecture already, and we've fixed all issues
   that were found, but if you find any new vulnerabilities, please report them to support@gruntwork.io!




## Switch over DNS

The Reference Architecture is typically deployed with "placeholder" domain names (e.g., `your-company-aws.com`) to make
testing easy and safe. Once your apps start passing tests, you can switch over your real domain names to point to
the Reference Architecture as follows:

1. We recommend managing all DNS entries using [Route 53](https://aws.amazon.com/route53/). If you bought your
   production domain name using some other registrar, you can either configure [Route 53 as the DNS
   Service](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/MigratingDNS.html) for your existing domain name
   or [transfer the domain name entirely to Route
   53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/domain-transfer-to-route-53.html).

1. If you have multiple AWS accounts (e.g., dev, stage, prod), we recommend that each one use its own, completely
   separate domain names (e.g., `my-company-dev.com`, `my-company-stage.com`, etc.). This reduces the chances of
   accidental errors (e.g., breaking prod DNS entries while trying to make changes to stage) and makes it harder for
   attackers to do damage (e.g., using cookies from pre-prod environment in a prod environment).

1. Before switching the domain names on your apps, make to use [AWS Certificate Manager
   (ACM)](https://aws.amazon.com/certificate-manager/) to request TLS certificates for your prod domain names and
   associate those certificates with your Load Balancers and CloudFront distributions. ACM is a great choice for
   TLS certificates, because they are (a) free and (b) issue in 1-2 minutes for domain names you own in Route 53, and
   (c) renew automatically!

1. To switch over your ALBs or ECS services to use different domain names, simply update the `domain_name` variables in
   the corresponding `terraform.tfvars`.




## Next steps

Now that you know how to migrate to the Reference Architecture, the next thing to learn is [how to deploy the
Reference Architecture from scratch](11-deploying-the-reference-architecture-from-scratch.md).