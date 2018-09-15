# SSH and VPN

In the previous section, you saw how to use [Monitoring, Alerting, and Logging](06-monitoring-alerting-logging.md) to
diagnose issues. Sometimes, that's not enough, and you need to connect directly to your servers using:

* [SSH](#ssh)
* [VPN](#vpn)




## SSH

You can use SSH to connect to any of your EC2 Instances as follows:

* [The traditional way: EC2 Key Pairs](the-traditional-way-ec2-key-pairs)
* [The better way: ssh-grunt](#the-better-way-ssh-grunt)

### The traditional way: EC2 Key Pairs

When you launch an EC2 Instance in AWS, you can specify an [EC2 Key Pair](
http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html) that can be used to SSH into the EC2 Instance.
This suffers from an important problem: usually more than one person needs access to the EC2 Instance, which means
you have to share this key with others. Sharing secrets of this sort is a security risk. Moreover, if someone leaves the
company, to ensure they no longer have access, you'd have to change the Key Pair, which requires redeploying all of your
servers.


### The better way: ssh-grunt

To solve the "key sharing" problem, Gruntwork implemented [ssh-grunt](
https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt), a tool that enables each member of your
team to log in to every EC2 Instance with their own IAM user name and their own SSH key. Here's how it works:

#### One-Time Setup

1. Log in to the AWS Web Console with your IAM User account.

1. Go to your IAM User profile page, select the **Security credentials** tab, and click **Upload SSH public key**.
   Now upload your _public_ SSH key (e.g. `~/.ssh/id_rsa.pub`). Do NOT upload your private key. 

1. Now make sure your IAM User account is a member of either the `ssh-grunt-users` or `ssh-grunt-sudo-users` group.
   By being a member of one of these IAM Groups, any EC2 Instance configured to use these IAM Groups will permit
   you to login as either a non-`sudo` user or `sudo` user, depending on which IAM Group you're in.
   
1. Note that your linux username is based on your IAM User name according to the [ssh-grunt guidelines](
   https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt#syncing-users-from-iam). For example:
    * The IAM User name `josh` will be the linux username `josh`.
    * The IAM User name `josh@gruntwork.io` will be the linux username `josh`
    * The IAM User name `_gruntwork.josh.padnick` will be the linux username `gruntwork_josh_padnick`.

For more information, see the [ssh-grunt documentation](https://github.com/gruntwork-io/module-security/tree/master/modules/ssh-grunt#how-it-works)

#### SSH to an EC2 Instance

As an example, suppose that:

- Your IAM User name is `josh`.
- You've uploaded your public SSH key to your IAM User profile.
- Your private key is located at `/Users/josh/.ssh/id_rsa` on your local machine.
- Your EC2 Instance's IP address is `1.2.3.4`. 

Then you can SSH to the EC2 Instance as follows:

```bash
# Do this once to load your SSH Key into the SSH Agent
ssh-add /Users/josh/.ssh/id_rsa

# Every time you want to login to an EC2 Instance, use this command
ssh josh@1.2.3.4
```   




## VPN

For security reasons, just about all of your EC2 Instances run in private subnets, which means they do not have a 
public IP address, and cannot be reached directly from the public Internet. This reduces the "surface area" that 
attackers can reach. Of course, we still need access into the VPCs, so we expose a single entrypoint into the network:
an [OpenVPN server](https://openvpn.net/).

The idea is that you use an OpenVPN client to connect to the OpenVPN server, which gets you "in" to the network, and
you can then connect to other resources in the account as if you were making requests from the OpenVPN server itself.

Here are the steps you'll need to take:

* [One-time setup](#vpn-one-time-setup)
* [Connect to the OpenVPN server](#connect-to-the-openvpn-server)
* [Connect to other resources](#connect-to-other-resources)


### VPN one-time setup

The very first time you want to use OpenVPN, you need to:

* [Install an OpenVPN client](#install-an-openvpn-client)
* [Join the OpenVPN IAM group](#join-the-openvpn-iam-group)
* [Use openvpn-admin to generate a configuration file](#use-openvpn-admin-to-generate-a-configuration-file)

#### Install an OpenVPN client

There are free and paid OpenVPN clients available for most major operating systems:

* **OS X**: [Tunnelblick](https://tunnelblick.net/) or [Viscosity](https://www.sparklabs.com/viscosity/).
* **Windows**: [official client](https://openvpn.net/index.php/open-source/downloads.html).
* **Linux**: `apt-get install openvpn` or `yum install openvpn`.

#### Join the OpenVPN IAM group
  
To get access to the OpenVPN server, you must be a member of the `openvpn-server-Users` IAM group. You or an admin can
add your IAM user to this group in the [IAM page](https://console.aws.amazon.com/iam/home?region=ap-southeast-2#/groups/openvpn-server-Users).

#### Use openvpn-admin to generate a configuration file

To connect to an OpenVPN server, you need an OpenVPN configuration file, which includes a certificate that you can use
to authenticate. To generate this configuration file, do the following:

1. Install the latest [openvpn-admin binary](https://github.com/gruntwork-io/package-openvpn/releases) for your OS.

1. Set up your AWS credentials using any of the options supported by [AWS CLI 
   tools](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html). Typically, environment 
   variables are the easiest and most secure.

1. Run `openvpn-admin request --aws-region ap-southeast-2`.
   
1. This will create your OpenVPN configuration file in the current folder.   

1. Load this configuration file into your OpenVPN client.

### Connect to the OpenVPN server

To connect to the OpenVPN server, simply click the "Connect" button next to your configuration file in the OpenVPN 
client! After a few seconds, you should be connected.

 
### Connect to other resources
 
Now that you're connected to VPN, you can connect to other resources in your AWS account. For example, if you followed
the ssh-grunt setup instructions above, you can SSH to an EC2 Instance with private IP address `1.2.3.4` as follows:

```bash
ssh <your_username>@1.2.3.4

# Example:
ssh josh@1.2.3.4
```

Similarly, non-production resources, such as a load balancer in the staging environment, or Jenkins in the mgmt 
environment, should now be accessible to you. 
 
Note: we run OpenVPN in "split tunnel" mode. That means that only the IP addresses we have explicitly opted into 
(namely, the private IP addresses in your AWS account) will be routed over VPN. Other IP addresses, such as requests
you make from your computer to YouTube, GMail, Spotify, etc, are NOT routed over VPN. This dramatically reduces the 
load on your OpenVPN server and your bandwidth usage in AWS.




## Next steps

Now that you know how to connect to your servers, let's talk about [auth for your AWS account(s)](08-accounts-and-auth.md).