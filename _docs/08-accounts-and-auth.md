# Accounts and Auth

In the last section, you learned about connecting to your servers using [SSH and VPN](07-ssh-vpn.md). In this section,
you'll learn about connecting to your AWS accounts:

* [Auth basics](#auth-basics)
* [Account setup](#account-setup)
* [Authenticating](#authenticating)




## Auth basics

For an overview of AWS authentication, including how to authenticate on the command-line, we **strongly** recommend
reading [A Comprehensive Guide to Authenticating to AWS on the Command
Line](https://blog.gruntwork.io/a-comprehensive-guide-to-authenticating-to-aws-on-the-command-line-63656a686799).




## Account setup

All of your AWS resources are deployed into a single account. This makes it easy to manage everything. 

In the future, you may want to consider putting each environment (e.g., stage, prod, etc) into a separate AWS account. 
This gives you more fine grained control over who can access what and improves isolation and security, as a mistake or 
breach in one account is unlikely to affect the others. The downside is overhead: it takes more time to set up multiple
accounts and more time to switch between them during day-to-day work. If you need help with multi-account setup, email
support@gruntwork.io.




## Authenticating

Some best practices around authenticating to your AWS account:

* [Enable MFA](#enable-mfa)
* [Use a password manager](#use-a-password-manager)
* [Don't use the root user](#dont-user-the-root-user)

Note that most of this section comes from the [Gruntwork Security Best Practices 
document](https://docs.google.com/document/d/e/2PACX-1vTikva7hXPd2h1SSglJWhlW8W6qhMlZUxl0qQ9rUJ0OX22CQNeM-91w4lStRk9u2zQIn6lPejUbe-dl/pub), so make sure to read through that for more info.

### Enable MFA

Always enable multi-factor authentication (MFA) for your AWS account. That is, in addition to a password, you must
provide a second factor to prove your identity. The best option for AWS is to install [Google
Authenticator](https://support.google.com/accounts/answer/1066447?hl=en) on your phone and use it to generate a one-time
token as your second factor.


### Use a password manager

Never store secrets in plain text. Store your secrets using a secure password manager, such as 
[pass](https://www.passwordstore.org/), [OS X Keychain](https://en.wikipedia.org/wiki/Keychain_(software)), or
[KeePass](http://keepass.info/). You can also use cloud-based password managers, such as 
[1Password](https://1password.com/) or [LastPass](https://www.lastpass.com/), but be aware that since they have 
everyone's passwords, they are inherently much more tempting targets for attackers. That said, any reasonable password
manager is better than none at all!


### Don't use the root user

AWS uses the [Identity and Access Management (IAM)](https://aws.amazon.com/iam/) service to manage users and their 
permissions. When you first sign up for an AWS account, you are logged in as the *root user*. This user has permissions 
to do everything in the account, so if you compromise these credentials, you’re in deep trouble. 

Therefore, right after signing up, you should:

1. Enable MFA on your root account. Note: we strongly recommend making a copy of the MFA secret key. This way, if you 
   lose your MFA device (e.g. your iPhone), you don’t lose access to your AWS account. To make the backup, when 
   activating MFA, AWS will show you a QR code. Click the "show secret key for manual configuration" link and save that 
   key to a secure password manager. 

1. Make sure you use a very long and secure password. Never share that password with anyone. If you need to store it 
   (as opposed to memorizing it), only store it in a secure password manager.
    
1. Use the root account to create a separate IAM user for yourself and your team members with more limited IAM 
   permissions. You should manage permissions using IAM groups. See the [iam-groups 
   module](https://github.com/gruntwork-io/module-security/tree/master/modules/iam-groups) for details.

1. Use IAM roles when you need to give limited permissions to tools (for eg, CI servers or EC2 instances).

1. Require all IAM users in your account to use MFA.

1. Never use the root IAM account again.





## Next steps

Now that you know how to authenticate, you may want to take a look through this list of [Gruntwork
Tools](09-gruntwork-tools.md).