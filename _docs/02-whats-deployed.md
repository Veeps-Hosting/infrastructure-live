# What's deployed?

Now that you've read through the basic [Architecture overview](01-architecture-overview.md), it's time to look at what
is deployed and how to access it. This document contains a few links and pointers to particularly useful resources in
the following environments:

* [Prod](#prod-environment)
* [Stage](#stage-environment)
* [Mgmt](#mgmt-environment)




## Prod environment

* Sample frontend app: https://www.propertyiq-cloud.net/sample-app-frontend
* Sample backend app: https://services.veeps-hosting.aws/sample-app-backend (only accessible from within the VPC, see [SSH and VPN](07-ssh-vpn.md))
* Static content: https://static.propertyiq-cloud.net




## Stage environment

* Sample frontend app: https://stage.propertyiq-cloud.net/sample-app-frontend
* Sample backend app: https://services.veeps-hosting.aws/sample-app-backend (only accessible from within the VPC, see [SSH and VPN](07-ssh-vpn.md))
* Static content: https://static-stage.propertyiq-cloud.net



## Mgmt environment

* Bastion host (only accessible from Veeps Hosting's office IP addresses, see [SSH and VPN](07-ssh-vpn.md)):
    * `bastion.propertyiq-cloud.net`
* Jenkins: https://jenkins.propertyiq-cloud.net (only accessible  from Veeps Hosting's office IP addresses, see [Build, tests, and deployment (CI/CD)](05-ci-cd.md))






## Next steps

Next up, we'll go through [How the code is organized](03-how-code-is-organized.md).