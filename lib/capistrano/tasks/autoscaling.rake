require 'capistrano/helpers/aws_helper'
require 'capistrano/helpers/cap_helper'

namespace :load do
  task :defaults do
    set :aws_autoscaling, true
    set :aws_region, 'us-west-2'
    set :aws_deploy_roles, %i{web app db}
    set :aws_ip_type, 'public_dns_name'
    set :aws_lifecycle_states, AwsHelper::LIFECYCLE_STATES
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
    aws_deploy_roles = symbolize_roles(fetch(:aws_deploy_roles))
    aws_deploy_user = fetch(:aws_deploy_user)

    ec2_instances.each {|instance|
      if ec2_instances.first == instance
        server instance, user: aws_deploy_user, roles: aws_deploy_roles, primary: true
        puts("First Server: #{instance} - #{aws_deploy_roles}")
      else
        server instance, user: aws_deploy_user, roles: sanitize_roles(aws_deploy_roles)
        puts("Server: #{instance} - #{sanitize_roles(aws_deploy_roles)}")
      end
    }

  end

  def fetch_ec2_instances
    region = fetch(:aws_region)
    key = fetch(:aws_access_key_id)
    secret = fetch(:aws_secret_access_key)
    group_name = fetch(:aws_autoscaling_group_name)
    ip_type = fetch(:aws_ip_type)
    profile = fetch(:aws_profile)
    lifecycle_states = fetch(:aws_lifecycle_states)

    instances = get_instances(region, key, secret, group_name, ip_type, aws_profile: profile, lifecycle_states: lifecycle_states)

    if instances.empty?
      raise "No instances in Auto Scaling group '#{group_name}' with lifecycle state #{lifecycle_states.join(' or ')}"
    end

    puts("Found #{instances.count} servers (#{instances.join(',')}) for Auto Scaling Group: #{group_name} ")

    instances
  end
end