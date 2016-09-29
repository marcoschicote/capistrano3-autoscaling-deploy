require 'aws-sdk'

module AwsHelper
  def get_instances(aws_region, aws_access_key_id, aws_secret_access_key, aws_autoscaling_group_name)
    aws_credentials = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
    retrieve_ec2_instances(aws_region, aws_autoscaling_group_name, aws_credentials)
  end

  private

  def retrieve_ec2_instances(aws_region, autoscaling_group_name, aws_credentials)
    instances = fetch_autoscaling_group_instances(aws_region, autoscaling_group_name, aws_credentials)

    if instances.empty?
      autoscaling_dns = []
    else
      instance_ids = instances.map(&:instance_id)
      ec2 = Aws::EC2::Resource.new(region: aws_region, credentials: aws_credentials)
      # info("Auto Scaling Group instances ids: #{instance_ids}")
      autoscaling_dns = instance_ids.map do |instance_id|
        ec2.instance(instance_id).public_dns_name
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