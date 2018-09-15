# Infrastructure walkthrough

Congratulations, you've found Veeps Hosting's infrastructure! All of the infrastructure is defined and managed 
*as code*. This documentation will walk you through all of that code so you know how to run things in dev, how to 
deploy changes to prod, how to find metrics and logs, and just about everything else you need to know to make use of 
this infrastructure.  

Please note that this infrastructure code was originally assembled by [Gruntwork](http://gruntwork.io) using a 
number of pre-built [Infrastructure Packages](https://github.com/gruntwork-io/toc). Each individual Infrastructure
Package contains thorough documentation for a single piece of infrastructure; the goal of the documentation in this
README is to present the "Big Picture" view of how all the different infrastructure pieces comes together.
 
 
 
 

## Reference Architecture Training Video

You can find a series of short videos that teaches you how to use the Reference Architecture here: [Gruntwork Reference 
Architecture Walkthrough](https://training.gruntwork.io/p/reference-architecture-walkthrough). Please ask your admin
or email [support@gruntwork.io](mailto:support@gruntwork.io) for the coupon code that lets you access this training 
course for free. 

 
 
 


## The Walkthrough

1. [Architecture overview](01-architecture-overview.md)

1. [What's deployed](02-whats-deployed.md)

1. [How the code is organized](03-how-code-is-organized.md)

1. [Running an App in the Dev Environment](04-dev-environment.md)

1. [Build, tests, and deployment (CI/CD)](05-ci-cd.md)

1. [Monitoring, Alerting, and Logging](06-monitoring-alerting-logging.md)

1. [SSH and VPN](07-ssh-vpn.md)

1. [Accounts and Auth](08-accounts-and-auth.md)

1. [Gruntwork Tools](09-gruntwork-tools.md)

1. [Migration](10-migration.md)

1. [Deploying the Reference Architecture from scratch](11-deploying-the-reference-architecture-from-scratch.md)