require '../helpers/aws'
require '../helpers/cap'

namespace :load do
  task :defaults do
    set :aws_autoscaling, true
    set :aws_region, 'us-west-2'
  end
end

namespace :deploy do
  before :starting do
    invoke 'autoscaling_deploy:setup_instances' if fetch(:aws_autoscaling)
  end
end

namespace :autoscaling_deploy do
  include AWS
  include Cap

  desc 'Add server from Auto Scaling Group.'
  task :setup_instances do
    ec2_instances = fetch_ec2_instances

    ec2_instances.inject(instances) { |acc, instance|
      acc[instance.ip_address] = fetch(:aws_deploy_roles)
      acc
    }

    instances.each {|instance, roles|
      if instances.first[0] == instance
        server instance, *roles
        logger.info("First Server: #{instance} - #{roles}")
      else
        logger.info("Server: #{instance} - #{sanitize_roles(roles)}")
        server instance, *sanitize_roles(roles)
      end
    }

  end

  def fetch_ec2_instances
    region = fetch(:aws_region)
    key = fetch(:aws_access_key_id)
    secret = fetch(:aws_secret_access_key)
    group_name = fetch(:autoscaling_group_name)

    instances = get_instances(region, key, secret, group_name)

    logger.info("Found #{instances.count} servers for Auto Scaling Group: #{group_name} ")
  end



  before :deploy, 'autoscaling_deploy:setup_instances'
end