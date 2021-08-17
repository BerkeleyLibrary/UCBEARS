# Framework

A Rails umbrella application for miscellaneous library forms, with support
for CalNet authentication and reading/writing patron records.

Original spec: “[Framework & Forms](https://docs.google.com/document/d/1wB4MGg-8mp1DdYjvCuFGs3n9Q6g0HBaESdTlqPUzCo4)”
(Google Docs)

## Table of Contents

- [For Developers](#for-developers)
- [Deployment](#deployment)
- [Logging](#logging)

## For Developers

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## Deployment

Framework is deployed to the staging and production Docker swarms, at the following
URLs:

- staging: [https://framework.ucblib.org/home](https://framework.ucblib.org/home)
- production: [https://framework.lib.berkeley.edu/home/](https://framework.lib.berkeley.edu/home/)

## Logging

Logs are aggregated in Amazon CloudWatch.

Staging and production logs are aggregated in Amazon CloudWatch.

- [staging](https://us-west-1.console.aws.amazon.com/cloudwatch/home?region=us-west-1#logStream:group=staging/framework/rails;streamFilter=typeLogStreamPrefix)
- [production](https://us-west-1.console.aws.amazon.com/cloudwatch/home?region=us-west-1#logStream:group=production/framework/rails;streamFilter=typeLogStreamPrefix)

You'll need to sign in with the IAM account alias `uc-berkeley-library-it`
and then with your IAM user name and password (created by the DevOps team).

