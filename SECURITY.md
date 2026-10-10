# Security policy

## Supported versions

Security fixes are released for the latest 2.x version. Versions before 2.0 are no longer maintained.

| Version | Supported |
|---|---|
| 2.x | Yes |
| < 2.0 | No |

## Reporting a vulnerability

Please don't open a public issue for security problems.

Report it privately through GitHub instead: go to the repository's **Security** tab and click **Report a vulnerability**, or use [this link](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/security/advisories/new). Include what you found, how to reproduce it, and which version you used.

You should get a reply within a week. Once a fix is ready, it's released as a new version and the issue is published as a GitHub security advisory, crediting you unless you'd rather stay anonymous.

## Scope

This gem looks up instances with read-only AWS APIs (`autoscaling:DescribeAutoScalingGroups` and `ec2:DescribeInstances`) and adds them as Capistrano servers. Problems with how it handles AWS credentials, or ways to make a deploy target the wrong hosts, are in scope. Vulnerabilities in Capistrano, the AWS SDK or other dependencies should be reported to those projects.
