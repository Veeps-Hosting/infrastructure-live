# Architecture Overview

Let's start by talking about your overall architecture. Veeps Hosting's architecture is deployed on top of 
[Amazon Web Services (AWS)](https://aws.amazon.com/) using the [Gruntwork Reference 
Architecture](https://www.gruntwork.io/reference-architecture/). 

Here's a diagram that shows an overview of what the Reference Architecture looks like:

![Architecture Diagram](_images/ref-arch-full.png)

Note that the Reference Architecture is highly customizable, so what's deployed may be a bit different than what's
in the diagram.  Here is an overview of what's actually deployed:

1. [Infrastructure as code](#infrastructure-as-code)
1. [Environments](#environments)
1. [VPCs and subnets](#vpcs-and-subnets)
1. [Load balancers](#load-balancers)
1. [Auto Scaling Groups](#auto-scaling-groups)
1. [Data stores](#data-stores)
1. [OpenVPN server](#openvpn-server)
1. [Jenkins](#jenkins)
1. [Monitoring, log aggregation, alerting](#monitoring-log-aggregation-alerting)
1. [DNS and TLS](#dns-and-tls)
1. [Static content, S3, and CloudFront](#static-content-s3-and-cloudfront)
1. [Lambda](#lambda)
1. [Security](#security)




## Infrastructure as code

All of Veeps Hosting's infrastructure is managed as **code**, primarily using [Terraform](https://www.terraform.io/). 
That is, instead of clicking around a web UI or SSHing to a server and manually executing commands, the idea behind 
infrastructure as code (IAC) is that you write code to define your infrastructure and you let an automated tool (e.g.,
Terraform) apply the code changes to your infrastructure. This has a number of benefits:

* You can automate your entire provisioning and deployment process, which makes it much faster and more reliable than 
  any manual process.

* You can represent the state of your infrastructure in source files that anyone can read rather than a sysadmin's head.

* You can store those source files in version control, which means the entire history of your infrastructure is 
  captured in the commit log, which you can use to debug problems, and if necessary, roll back to older versions.

* You can validate each infrastructure change through code reviews and automated tests.

* You can package your infrastructure as reusable, documented, battle-tested modules that make it easier to scale and 
  evolve your infrastructure. In fact, much of the infrastructure code in this architecture is powered by modules
  created by Gruntwork, which are called [Infrastructure 
  Packages](https://blog.gruntwork.io/gruntwork-infrastructure-packages-7434dc77d0b1).

For more info on Infrastructure as Code and Terraform, check out [A Comprehensive Guide to 
Terraform](https://blog.gruntwork.io/a-comprehensive-guide-to-terraform-b3d32832baca).

  
  
  
## Environments

The infrastructure is deployed across multiple environments:

* **mgmt**: DevOps tooling, such as the OpenVPN server. 

* **prod**: Production environment. 

* **stage**: Pre-production environment. 





## VPCs and subnets

Each environment lives in a separate [Virtual Private Cloud (VPC)](https://aws.amazon.com/vpc/), which is a logically 
isolated section within an AWS account. Each VPC defines a virtual network, with its own IP address space and rules for 
what can go in and out of that network. The IP addresses within each VPC are further divided into multiple 
[subnets](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html), where each subnet controls the 
routing for its IP address. 

* *Public subnets* are directly accessible from the public Internet.
* *Private subnets* are only accessible from within the VPC. 

Just about everything in this infrastructure is deployed in private subnets to reduce the surface area to attackers. 
The only exceptions are load balancers and the [OpenVPN server](#openvpn-server), 
both of which are described below. 

To learn more about VPCs and subnets, check out the Gruntwork [vpc-app module 
documentation](https://github.com/gruntwork-io/module-vpc/tree/master/modules/vpc-app).




## Load balancers

Traffic from the public Internet (e.g., requests from your users) initially goes to a *public load balancer*, which 
proxies the traffic to your apps. This allows you to run multiple copies of your application for scalability and high 
availability. The load balancers being used are:

* [Application Load Balancer (ALB)](https://aws.amazon.com/elasticloadbalancing/applicationloadbalancer/): The ALB is a
  load balancer managed by AWS that is designed for routing HTTP and HTTPS traffic. The advantage of using a managed
  service is that AWS takes care of fault tolerance, security, and scaling the load balancer for you automatically. 
  Check out [module-load-balancer](https://github.com/gruntwork-io/module-load-balancer/) for more info on how to use 
  the ALB.

We also deploy an *internal* load balancer in the private subnets. This load balancer is not accessible to the public.
Instead, it's used as a simple way to do service discovery: every backend service registers with the load balancer at a
particular path, and all services know to send requests to this load balancer to talk to other services.




## Auto Scaling Groups

Your application code is packaged as an [Amazon Machine Image 
(AMI)](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) using [Packer](https://www.packer.io/) and 
deployed across an [Auto Scaling Group 
(ASG)](http://docs.aws.amazon.com/autoscaling/latest/userguide/AutoScalingGroup.html). An ASG makes it easy to run 
your app across multiple EC2 Instances, scale the number of Instances up or down in response to load, and redeploy 
Instances that crashed.

For more info on ASGs, see [module-asg](https://github.com/gruntwork-io/module-asg). 




## Data stores

The infrastructure includes the following data stores:

1. **Aurora**: Aurora is deployed using [Amazon's Relational Database Service 
  (RDS)](https://aws.amazon.com/rds/), including automatic failover, backups, and replicas. Check out 
  [module-data-storage](https://github.com/gruntwork-io/module-data-storage) for more info.




## Lambda

We have deployed several example [Lambda functions](https://aws.amazon.com/lambda/) to show how you can build 
serverless applications. Check out the [package-lambda 
docs](https://github.com/gruntwork-io/package-lambda/tree/master/modules/lambda) for background info.




## OpenVPN server

To reduce your surface area to attackers, just about all of the resources in this infrastructure run in private subnets, 
which are not accessible from the public Internet at all. To allow Veeps Hosting's employees to access these 
private resources, we expose a single server publicly: an [OpenVPN server](https://openvpn.net/). Once you connect to 
the server using a VPN client, you are "in the network", and will be able to access the private resources (e.g., you 
will be able to SSH to your EC2 Instances).

For more info, see [SSH and VPN](07-ssh-vpn.md) and [package-openvpn](https://github.com/gruntwork-io/package-openvpn/).




## Jenkins

We have set up [Jenkins](https://jenkins.io/) as a Continuous Integration (CI) server. After every commit, a Jenkins 
job runs your build, tests, packaging, and automated deployment steps.
 
For more info, see [Build, tests, and deployment (CI/CD)](05-ci-cd.md) and
[module-ci](https://github.com/gruntwork-io/module-ci).




## Monitoring, log aggregation, alerting

You can find metrics, log files from all your servers, and subscribe to alert notifications using [Amazon 
CloudWatch](https://aws.amazon.com/cloudwatch/).  

For more info, see [Monitoring, Alerting, and Logging](06-monitoring-alerting-logging.md) and
[module-aws-monitoring](https://github.com/gruntwork-io/module-aws-monitoring).   




## DNS and TLS

We are using [Amazon Route 53](https://aws.amazon.com/route53/) to configure DNS entries for all your services. We
have configured SSL/TLS certificates for your domain names using [Amazon's Certificate Manager 
(ACM)](https://aws.amazon.com/certificate-manager/), which issues certificates that are free and renew automatically.

For more info, see [What's deployed](02-whats-deployed.md).




## Static content, S3, and CloudFront

All static content (e.g., images, CSS, JS) is stored in [Amazon S3](https://aws.amazon.com/s3/) and served via the 
[CloudFront](https://aws.amazon.com/cloudfront/) CDN. This allows you to offload all the work of serving static content 
from your app server and reduces latency for your users.

For more info, see [What's deployed](02-whats-deployed.md) and
[package-static-assets](https://github.com/gruntwork-io/package-static-assets).




## Security

We have configured security best practices in every aspect of this infrastructure:
 
* **Network security**: see [VPCs and subnets](#vpcs-and-subnets).

* **Server access**: see [SSH and VPN](07-ssh-vpn.md).

* **Application secrets**: see the GruntKMS section of [Running an App in the Dev Environment](04-dev-environment.md)
  and [gruntkms](https://github.com/gruntwork-io/gruntkms).
 
* **User accounts**: see [Accounts and Auth](08-accounts-and-auth.md).
 
* **Auditing**: see the [CloudTrail module](https://github.com/gruntwork-io/module-security/tree/master/modules/cloudtrail).

* **Intrusion detection**: see the [fail2ban module](https://github.com/gruntwork-io/module-security/tree/master/modules/fail2ban).

* **Security updates**: see the [auto-update module](https://github.com/gruntwork-io/module-security/tree/master/modules/auto-update).

* **OS hardening**: see the [os-hardening module](https://github.com/gruntwork-io/module-security/tree/master/modules/os-hardening).

* **End-to-end encryption**: all data in transit is encrypted using TLS and all data at rest lives in encrypted volumes
  and data stores. See [Running an App in the Dev Environment](04-dev-environment.md).

Check out [Gruntwork Security Best Practices](https://docs.google.com/document/d/e/2PACX-1vTikva7hXPd2h1SSglJWhlW8W6qhMlZUxl0qQ9rUJ0OX22CQNeM-91w4lStRk9u2zQIn6lPejUbe-dl/pub) for more info.





## Next steps

Next up, let's have a look at [What's deployed](02-whats-deployed.md).



