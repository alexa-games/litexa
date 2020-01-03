# Appendix: AWS Permissions

Your IAM user will require the following [minimum permissions](#minimum-permissions). You can [create a
custom policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_create.html)
to define these permissions and attach it to your user. This appendix
will cover an explanation of each permission and the resources they apply to, but
feel free to skip to the [sample policy template](#sample-policy-document) at the end,
which you can use and modify for your own account.

## IAM

The following permissions all apply to the role `litexa_handler_lambda`.

* AttachRolePolicy
* CreateRole
* GetRole
* ListAttachedRolePolicies
* PassRole

## Lambda

The following permissions all apply to the Lambda function name structure
`*_*_litexa_handler`, where `*` is a wildcard.

* AddPermission
* CreateAlias
* CreateFunction
* GetAlias
* GetFunctionConfiguration
* GetPolicy
* ListAliases
* RemovePermission
* UpdateFunctionCode
* UpdateFunctionConfiguration

## DynamoDB

The following permissions all apply to the DynamoDB table name structure
`*_*_litexa_handler_state`, where `*` is a wildcard.

* CreateTable
* DescribeTable

## S3

This permission automatically applies to all resources.

* ListAllMyBuckets

The following permissions apply to the S3 bucket defined in the
`s3Configuration.bucketName` field in your litexa.config.js/json/ts/coffee file.

* CreateBucket
* ListBucket

The following permissions apply to all objects in the S3 bucket defined
in the `s3Configuration.bucketName` field in your litexa.config.js/json/ts/coffee file.

* PutObject
* PutObjectAcl

## CloudWatch Logs

This permission applies to all Cloudwatch log groups.

* DescribeLogGroups

This permission automatically applies to all resources.

* CreateLogGroup

These permissions apply to CloudWatch log streams with the
log group name structure `*_*_litexa_handler,` where `*` is a wildcard.

* DescribeLogStreams
* PutRetentionPolicy

This permission requires the above resource plus wildcards for the log stream
and log stream name sections.

* GetLogEvents

## Minimum Permissions

Any resources with wildcards `*` can be replaced by the specific ARN,
but the wildcards are practical for creating multiple Litexa projects
in the same AWS account.

## Sample Policy Document

Remember to replace `myAccountId` and `myBucketName` with your AWS
account ID number and S3 bucket, respectively.

@[code lang=json](@/docs/book/litexa-iam-policy-template.json)
