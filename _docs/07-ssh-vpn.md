# SSH and VPN

In the previous section, you saw how to use [Monitoring, Alerting, and Logging](06-monitoring-alerting-logging.md) to
diagnose issues. Sometimes, that's not enough, and you need to connect directly to your servers using:

* [SSH](#ssh)
* [VPN](#vpn)




## SSH

You can use SSH to connect to any of your EC2 Instances as follows:

* [The traditional way: EC2 Key Pairs](the-traditional-way-ec2-key-pairs)
* [The better way: ssh-grunt](#the-better-way-ssh-grunt)
* [The bastion host](#the-bastion-host)
* [Local port forwarding](#local-port-forwarding)
* [Socks proxy](#socks-proxy)

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

### The Bastion Host

For security reasons, just about all of your EC2 Instances run in private subnets, which means they do not have a 
public IP address, and cannot be reached directly from the public Internet. This reduces the "surface area" that 
attackers can reach. Of course, we still need access into the VPCs, so we expose a single EC2 Instance to the public 
Internet that serves as the point of entry to the network. Because we will concentrate most of our security
efforts on this one EC2 Instance, it's easier to make it secure, and we call it the "bastion" (fortress) host.

The idea is that you must first connect to the bastion host, which gets you "in" to the network, and you can then use 
it as a "jump host" to connect to all the EC2 Instances in private subnets.

To SSH to the Bastion Host, find its public IP address in the [What's deployed documentation](02-whats-deployed.md) or
in the AWS Web Console. 
 
Now SSH in as follows:

1. First make sure the SSH key you uploaded to your IAM User profile above is in your 
   [ssh-agent](http://mah.everybody.org/docs/ssh) as follows:
   
    ```bash
    ssh-add /path/to/your/private/key
   
    # Example:
    ssh-add ~/.ssh/id_rsa
    ```

1. Now SSH to the Bastion Host:

    ```bash
    ssh -A <converted-iam-user-name>@<bastion-host-ip>
   
    # Example:
    ssh -A josh@1.2.3.4
    ```
   
    Note the use of `-A` to enable ssh-agent forwarding. This sends authentication requests back to your own computer,
    so that you can authenticate from the bastion host to other servers without having to copy your SSH key to the 
    bastion host.
   
1. Now that you're logged into the Bastion Host, you can SSH to the private IP address of any other EC2 Instance in the 
   network as follows:

    ```bash
    # From the Bastion Host
    ssh <private-ip-of-other-machine>
   
    # Example:
    ssh 10.0.0.1
    ```

Note that, per the [architecture overview](01-architecture-overview.md), the Bastion Host is located in the "mgmt" VPC,
and this VPC is [peered](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/vpc-peering.html) with all the other 
VPCs you may need to access.


### Local port forwarding

What if you want to access your database from your local environment? 

The database is located in a subnet that does not have direct Internet access, so you can only access the database 
through the Bastion Host. Fortunately, SSH has a feature called 
[local port forwarding](http://blog.trackets.com/2014/05/17/ssh-tunnel-local-and-remote-port-forwarding-explained-with-examples.html)
that will allow you to:

- Expose a port on your local machine.
- Route all traffic on that port directly to the Bastion Host and then forward it to a given port on a remote machine
  in the network.
  
As an example, imagine you want to connect to a Postgres database that runs in a private subnet, listening on port 
`5432` with the private IP address `10.0.0.1`. To connect to this DB from your computer, via the bastion host, run
the following command (note: make sure the security group of the Postgres database allows connections from the bastion 
host!):

```
ssh -L 8000:10.0.0.1:5432 <user>@<bastion-ip>
```

The command above tells your computer to forward requests to `localhost:8000` to the bastion host, which, in turn, will
forward them to the Postgres database at `10.0.0.1:5432`.

After running the command above, you can use a Postgres client on your own computer to connect to the Postgres database
as follows:

```
psql -host=localhost -port=8000
```


### SOCKS proxy

What if you want to route all requests in your web browser through the Bastion host so that you can view private sites?

SSH has a feature that allows you to treat the Bastion Host as a "SOCKS5 Proxy", which means that any app
on your local machine that knows how to speak the SOCKS5 protocol can route all of its traffic through the Bastion Host.
This means that you could, for example, browse the web as if you were doing so directly from the Bastion Host.

Setting up a SOCKS Proxy connection is surprisingly easy:

```
ssh -D 5000 <user>@<bastion-ip>
```

This will open a listener on your local machine's port 5000 and route all connections to the Bastion Host. 

Next, you need to configure our web browser to use the SOCKS Proxy. For example, to configure FireFox:
 
1. Go to **Preferences...** > **Advanced** > **Network**
1. Under **Connection**, select **Settings..**
1. Select **Manual Proxy Configuration** and under **HTTP Proxy:** enter `localhost` and port `5000` (or whatever port
   you chose).
1. Now click **OK** and visit http://whatismyip.akamai.com/ to verify that your IP address is now the public IP
   address of the Bastion Host.   




## VPN

(VPN is not configured)




## Next steps

Now that you know how to connect to your servers, let's talk about [auth for your AWS account(s)](08-accounts-and-auth.md).