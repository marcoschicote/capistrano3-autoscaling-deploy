[![Gem Version](https://badge.fury.io/rb/capistrano3-autoscaling-deploy.png)](http://badge.fury.io/rb/capistrano3-autoscaling-deploy)
[![Test](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/actions/workflows/test.yml/badge.svg)](https://github.com/marcoschicote/capistrano3-autoscaling-deploy/actions/workflows/test.yml)
# capistrano3-autoscaling-deploy
Capistrano 3 plugin for AWS Auto Scaling deploys.
 
 A lot of inspiration (and code) for how this gem was built come from https://github.com/gtforge/capistrano-autoscale-deploy
 I've also taken suggestions from the opened PRs against such repo.
 
 I'm mainly building this gem as the author for the gem above has dissapeared 
 and I need an updated version that uses Capistrano 3 and current version of 
 AWS CLI.

## Requirements

* aws-sdk-autoscaling ~> 1
* aws-sdk-ec2 ~> 1
* capistrano ~> 3


## Installation

Add this line to your application's Gemfile:

    gem 'capistrano3-autoscaling-deploy'

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install capistrano3-autoscaling-deploy

Add this line to your application's Capfile:

```ruby
require 'capistrano/autoscaling_deploy'
```

### Upgrading to 2.0

2.0 uses the current AWS SDK for Ruby (`aws-sdk-autoscaling` and `aws-sdk-ec2`) instead of the retired `aws-sdk` v2, so it no longer installs `aws-sdk` v2. If your own deploy code uses `aws-sdk` v2, add it to your Gemfile or, better, move that code to the current SDK.

Versions before 2.0 also loaded [capistrano-bundler](https://github.com/capistrano/bundler), which runs `bundle install` on your servers during deploy. 2.0 no longer does this. If your deploy relies on it, add it to your Gemfile:

    gem 'capistrano-bundler'

and require it in your Capfile:

```ruby
require 'capistrano/bundler'
```

## Usage

In the capistrano deploy script / stage files add the following lines

```ruby
set :aws_region, 'us-west-2'
set :aws_autoscaling_group_name, 'YOUR NAME OF AUTO SCALING GROUP NAME'
set :aws_deploy_roles, [:app, :web, :db]
set :aws_deploy_user, 'USER FOR SSH CONNECTION'
 
# optional: defaults to 'public_dns_name'
# select from ['public_ip_address', 'public_dns_name', 'private_ip_address', 'private_dns_name']
set :aws_ip_type, 'public_dns_name'
```

### AWS credentials

The credentials need read access to Auto Scaling and EC2 (`autoscaling:DescribeAutoScalingGroups` and `ec2:DescribeInstances`; the `AmazonEC2ReadOnlyAccess` managed policy covers both).

By default the gem uses the [AWS SDK's default credential chain](https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/credential-providers.html): environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`), `AWS_PROFILE` and the shared config and credentials files, AWS SSO, and ECS task or EC2 instance roles. This is the recommended setup, and it needs no settings.

To use a specific profile from your shared config:

```ruby
set :aws_profile, 'deploy'
```

You can still set static keys, but avoid committing them to your repository. If both are set they take precedence over `aws_profile`:

```ruby
set :aws_access_key_id, ENV['DEPLOY_AWS_ACCESS_KEY_ID']
set :aws_secret_access_key, ENV['DEPLOY_AWS_SECRET_ACCESS_KEY']
```

you can add more auto scaling configs to deploy to multiple auto scaling groups like a cluster

## How this works

This gem will fetch only running instances that have an auto scaling tag name you specified

It will then reject the roles of :db and the :primary => true for all servers found **but the first one** 

(from all auto scaling groups you have specified such as using more then once the auto scaling directive in your config - i.e cluster deploy)

this is to make sure a single working task does not run in parallel

you end up as if you defined the servers yourself like so:

````ruby
server ip_address1, :app, :db, :web, :primary => true
server ip_address2, :app, :web
server ip_address3, :app, :web
````

## Contributing

1. Fork it ( https://github.com/marcoschicote/capistrano3-autoscaling-deploy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Run the tests with `bundle exec rake test`. They use the AWS SDK's stubbed responses, so they don't need AWS credentials or network access.
