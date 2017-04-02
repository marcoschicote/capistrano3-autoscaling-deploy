require 'aws-sdk'

module AwsHelper
  IP_TYPES = %w(public_ip_address public_dns_name private_ip_address private_dns_name)

  def get_instances(aws_region, aws_access_key_id, aws_secret_access_key, aws_autoscaling_group_name, aws_ip_type)
    aws_credentials = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
    retrieve_ec2_instances(aws_region, aws_autoscaling_group_name, aws_credentials, aws_ip_type)
  end

  private

  def retrieve_ec2_instances(aws_region, autoscaling_group_name, aws_credentials, aws_ip_type)
    instances = fetch_autoscaling_group_instances(aws_region, autoscaling_group_name, aws_credentials)

    if instances.empty?
      autoscaling_dns = []
    else
      instance_ids = instances.map(&:instance_id)
      ec2 = Aws::EC2::Resource.new(region: aws_region, credentials: aws_credentials)
      # info("Auto Scaling Group instances ids: #{instance_ids}")
      aws_ip_type = 'public_dns_name' unless IP_TYPES.include? aws_ip_type
        
      autoscaling_dns = instance_ids.map do |instance_id|
        ec2.instance(instance_id).send(aws_ip_type.to_sym)
      end
    end

    autoscaling_dns
  end

  def fetch_autoscaling_group_instances(aws_region, autoscaling_group_name, aws_credentials)
    as = Aws::AutoScaling::Client.new(region: aws_region, credentials: aws_credentials)
    as_groups = as.describe_auto_scaling_groups(
        auto_scaling_group_names: [autoscaling_group_name],
        max_records: 1,
    ).auto_scaling_groups

    # info("Auto Scaling Groups: #{as_groups}")

    as_group = as_groups[0]

    # info("Auto Scaling Group instances: #{as_group.instances}")

    as_group.instances
  end

end
