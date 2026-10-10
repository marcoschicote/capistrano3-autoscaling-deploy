[![Gem Version](https://img.shields.io/gem/v/capistrano3-autoscaling-deploy)](https://rubygems.org/gems/capistrano3-autoscaling-deploy)
[![Test](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/actions/workflows/test.yml/badge.svg)](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/actions/workflows/test.yml)

# capistrano3-autoscaling-deploy

Capistrano 3 plugin that deploys to the instances of an AWS Auto Scaling group. Instead of listing servers in your stage files, the plugin asks AWS which instances are in service at deploy time and adds them as Capistrano servers.

## Requirements

* Ruby 3.3 or newer
* capistrano ~> 3
* aws-sdk-autoscaling ~> 1 and aws-sdk-ec2 ~> 1 (installed with the gem)

## Installation

Add the gem to your application's Gemfile:

```ruby
gem 'capistrano3-autoscaling-deploy', '~> 2.0'
```

and run `bundle install`.

Then add this line to your Capfile:

```ruby
require 'capistrano/autoscaling_deploy'
```

## Usage

In your deploy script or stage file (for example `config/deploy/production.rb`), set the Auto Scaling group to deploy to:

```ruby
set :aws_region, 'eu-west-1'
set :aws_autoscaling_group_name, 'my-app-production'
set :aws_deploy_user, 'deploy'
```

Before each deploy starts, the plugin adds every in-service instance in that group as a server. Don't also define those servers with `server` or `role`.

### Settings

| Setting | Default | Description |
|---|---|---|
| `aws_autoscaling_group_name` | none (required) | Name of the Auto Scaling group to deploy to. |
| `aws_region` | `'us-west-2'` | AWS region of the group. |
| `aws_deploy_user` | none | SSH user for the instances. If unset, Capistrano's usual SSH user applies. |
| `aws_deploy_roles` | `%i{web app db}` | Roles given to the instances. See [Roles](#roles). |
| `aws_ip_type` | `'public_dns_name'` | Address used to connect to each instance: `public_dns_name`, `public_ip_address`, `private_dns_name` or `private_ip_address`. Use a private one for instances without public addresses, for example when deploying through a bastion or from inside the VPC. |
| `aws_lifecycle_states` | `%w(InService)` | [Lifecycle states](https://docs.aws.amazon.com/autoscaling/ec2/userguide/ec2-auto-scaling-lifecycle.html) of the instances to deploy to. |
| `aws_profile` | none | Named AWS profile to use. See [AWS credentials](#aws-credentials). |
| `aws_access_key_id`, `aws_secret_access_key` | none | Static AWS keys. See [AWS credentials](#aws-credentials). |
| `aws_autoscaling` | `true` | Set to `false` to turn the plugin off, for example in a stage whose servers you define yourself. |

### AWS credentials

The credentials need read access to Auto Scaling and EC2: `autoscaling:DescribeAutoScalingGroups` and `ec2:DescribeInstances`. The `AmazonEC2ReadOnlyAccess` managed policy covers both.

By default the gem uses the [AWS SDK's default credential chain](https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/credential-providers.html): environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`), `AWS_PROFILE` and the shared config and credentials files, AWS SSO, and ECS task or EC2 instance roles. This is the recommended setup, and it needs no settings.

To use a specific profile from your shared config:

```ruby
set :aws_profile, 'deploy'
```

You can still set static keys, but don't commit them to your repository. If both are set, they take precedence over `aws_profile`:

```ruby
set :aws_access_key_id, ENV['DEPLOY_AWS_ACCESS_KEY_ID']
set :aws_secret_access_key, ENV['DEPLOY_AWS_SECRET_ACCESS_KEY']
```

### Roles

Every instance gets the roles in `aws_deploy_roles`, except that only the **first** instance gets `:db` and `primary: true`. That way tasks meant to run once, such as database migrations, don't run on every instance at the same time.

With three instances in the group and the default roles, you end up with the same servers as if you had written:

```ruby
server 'ip-1.example.com', roles: %i{web app db}, primary: true
server 'ip-2.example.com', roles: %i{web app}
server 'ip-3.example.com', roles: %i{web app}
```

## How it works

Before `deploy:starting`, the plugin:

1. Looks up the Auto Scaling group `aws_autoscaling_group_name`.
2. Keeps only the instances whose lifecycle state is in `aws_lifecycle_states`, and logs the ones it skips. Instances that are launching, on standby or being terminated are skipped by default. Health status isn't checked, so you can still deploy a fix when every instance is failing its health checks.
3. Reads each instance's `aws_ip_type` address from EC2.
4. Adds the instances as servers in the group's order, with roles as described in [Roles](#roles).

The deploy stops with an error if:

* the group doesn't exist,
* no instances are in the selected lifecycle states, or
* an instance has no address for `aws_ip_type`, for example `public_dns_name` in a private subnet.

## Upgrading to 2.0

2.0 uses the current AWS SDK for Ruby (`aws-sdk-autoscaling` and `aws-sdk-ec2`) instead of the retired `aws-sdk` v2, so it no longer installs `aws-sdk` v2. If your own deploy code uses `aws-sdk` v2, add it to your Gemfile or, better, move that code to the current SDK.

2.0 only deploys to instances whose lifecycle state is `InService`, and stops with an error if the Auto Scaling group doesn't exist or has no such instances. Before, it deployed to every instance in the group, including ones being launched or terminated, and carried on with no servers if the group was empty. To also deploy to other states, set `aws_lifecycle_states` (for example `%w(InService Standby)`).

Versions before 2.0 also loaded [capistrano-bundler](https://github.com/capistrano/bundler), which runs `bundle install` on your servers during deploy. 2.0 no longer does this. If your deploy relies on it, add `gem 'capistrano-bundler'` to your Gemfile and this line to your Capfile:

```ruby
require 'capistrano/bundler'
```

See [CHANGELOG.md](CHANGELOG.md) for all changes.

## Contributing

1. Fork it (https://github.com/marcoschicote/capistrano3-autoscaling-deploy/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new pull request

Run the tests with `bundle exec rake test`. They use the AWS SDK's stubbed responses, so they don't need AWS credentials or network access.

The code follows [Standard Ruby](https://github.com/standardrb/standard). Check it with `bundle exec rake standard`, or fix most offenses with `bundle exec standardrb --fix`. Running `bundle exec rake` does both the tests and the style check.

## Releasing

Releases are published to RubyGems from GitHub Actions using [trusted publishing](https://guides.rubygems.org/trusted-publishing/), so no API key is stored anywhere.

1. Update the version in `lib/capistrano/autoscaling_deploy/version.rb` and add a section to `CHANGELOG.md`, and merge them to `main`.
2. In the repository's **Actions** tab, run the **Release** workflow on `main`. It runs the tests, builds the gem, pushes the `vX.Y.Z` tag and publishes the gem.
