# Changelog

## Unreleased

### Fixed
- Instances without an address for `aws_ip_type` (for example `public_dns_name` in a private subnet) now stop the deploy with an error naming them. Before, they were all registered as one server with an empty hostname, and each was treated as the primary server ([#23](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/23)).
- The primary server is chosen by position in the Auto Scaling group, not by comparing hostnames ([#23](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/23)).

### Removed
- `lib/capistrano/autoscaling_deploy/autoscaling_deploy.rb`, an unused file that loaded the tasks a second time. Require `capistrano/autoscaling_deploy` in your Capfile, as the README says ([#24](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/24)).

## 2.0.0

First release since 1.6 (2017). See [Upgrading to 2.0](README.md#upgrading-to-20) before updating.

### Breaking changes
- Uses the current AWS SDK for Ruby (`aws-sdk-autoscaling` and `aws-sdk-ec2`) instead of the retired `aws-sdk` v2 ([#10](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/10)).
- No longer depends on or loads `capistrano-bundler`. Add it to your own Gemfile and Capfile if your deploy runs `bundle install` ([#11](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/11)).
- Only deploys to instances whose lifecycle state is `InService` ([#13](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/13)).
- Stops the deploy with an error if the Auto Scaling group doesn't exist or has no matching instances ([#13](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/13)).
- Requires Ruby 3.3 or newer.

### Added
- Uses the AWS SDK's default credential chain (environment variables, shared config files, SSO, ECS and EC2 roles) when `aws_access_key_id` and `aws_secret_access_key` aren't set ([#12](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/12)).
- `aws_profile` setting to use a named AWS profile ([#12](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/12)).
- `aws_lifecycle_states` setting to choose which lifecycle states to deploy to ([#13](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/13)).

### Fixed
- With the default roles, or roles given as strings, every instance got the `db` role instead of only the first one ([#19](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/19)).
- Setting only one of `aws_access_key_id` and `aws_secret_access_key` now raises a clear error instead of sending a `nil` key ([#12](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/12)).
- Instances are looked up in one EC2 call instead of one call per instance ([#10](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/10)).

### Development
- Real test suite using the AWS SDK's stubbed responses, run on GitHub Actions for Ruby 3.3, 3.4 and 4.0 ([#14](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/issues/14)).
- Releases are published to RubyGems from GitHub Actions with trusted publishing.

## 1.6 and earlier

See the [commit history](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/commits/master).
