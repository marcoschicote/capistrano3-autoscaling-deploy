[![Gem Version](https://badge.fury.io/rb/capistrano3-autoscaling-deploy.png)](http://badge.fury.io/rb/capistrano3-autoscaling-deploy)
# capistrano3-autoscaling-deploy
Capistrano 3 plugin for AWS Auto Scaling deploys.
 
 A lot of inspiration (and code) for how this gem was built come from https://github.com/gtforge/capistrano-autoscale-deploy
 I've also taken suggestions from the opened PRs against such repo.
 
 I'm mainly building this gem as the author for the gem above has dissapeared 
 and I need an updated version that uses Capistrano 3 and current version of 
 AWS CLI.

## Requirements

* aws-sdk ~> 2
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

## Usage

Set credentials with AmazonEC2ReadOnlyAccess permission in the capistrano deploy script / stage files add the following lines

```ruby
set :aws_region, 'us-west-2'
set :aws_access_key_id, 'YOUR AWS KEY ID'
set :aws_secret_access_key, 'YOUR AWS SECRET KEY'
set :aws_autoscaling_group_name, 'YOUR NAME OF AUTO SCALING GROUP NAME'
set :aws_deploy_roles, [:app, :web, :db]
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

1. Fork it ( http://github.com/<my-github-username>/capistrano3-autoscaling-deploy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

To test while developoing just `bundle console` on the project root directory and execute 
`Capistrano::AutoScalingDeploy::VERSION` for a quick test
