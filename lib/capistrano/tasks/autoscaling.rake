require 'capistrano/helpers/aws_helper'
require 'capistrano/helpers/cap_helper'

namespace :load do
  task :defaults do
    set :aws_autoscaling, true
    set :aws_region, 'us-west-2'
  end
end

namespace :deploy do
  before :starting, :check_autoscaling_hooks do
    invoke 'autoscaling_deploy:setup_instances' if fetch(:aws_autoscaling)
  end
end

namespace :autoscaling_deploy do
  include AwsHelper
  include CapHelper

  desc 'Add server from Auto Scaling Group.'
  task :setup_instances do
    ec2_instances = fetch_ec2_instances
    aws_deploy_roles = fetch(:aws_deploy_roles)

    ec2_instances.each {|instance|
      if ec2_instances.first[0] == instance
        server instance, *roles
        info("First Server: #{instance} - #{aws_deploy_roles}")
      else
        server instance, *sanitize_roles(roles)
        info("Server: #{instance} - #{sanitize_roles(aws_deploy_roles)}")
      end
    }

  end

  def fetch_ec2_instances
    region = fetch(:aws_region)
    key = fetch(:aws_access_key_id)
    secret = fetch(:aws_secret_access_key)
    group_name = fetch(:aws_autoscaling_group_name)

    instances = get_instances(region, key, secret, group_name)

    info("Found #{instances.count} servers for Auto Scaling Group: #{group_name} ")

    instances
  end
end