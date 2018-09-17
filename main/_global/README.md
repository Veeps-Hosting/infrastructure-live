# Global Account Resources

This folder contains the templates that define AWS resources which are global across this entire AWS account and all
regions within it.

This includes resources like CloudTrail, IAM Groups, Route53, SNS Topics, and S3 Buckes. Note that some of these 
resources may be _created_ in a specific AWS Region, but they are generally _accessible_ in any region. For example, 
an S3 Bucket is created in a specific AWS Region, but its Bucket name is globally unique across all regions and it can 
be accessed from any other AWS Region.

Click on each subfolder to see its documentation.
