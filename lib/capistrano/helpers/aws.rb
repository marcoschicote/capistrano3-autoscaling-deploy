require 'aws-sdk'

module AWS
  def get_instances(aws_region, aws_access_key_id, aws_secret_access_key, aws_autoscaling_group_name)
    aws_credentials = Aws::Credentials(aws_access_key_id, aws_secret_access_key)
    fetch_ec2_instances(aws_region, aws_autoscaling_group_name, aws_credentials)
  end

  private

  def fetch_ec2_instances(aws_region, autoscaling_group_name, aws_credentials)
    instances = fetch_autoscaling_group_instances(aws_region, aws_credentials, autoscaling_group_name)

    if instances.empty?
      autoscaling_dns = []
    else
      instance_ids = instances.map(&:instance_id)
      ec2 = Aws::EC2::Client.new(region: aws_region, credentials: aws_credentials)
      autoscaling_dns = instance_ids.map do |instance_id|
        ec2.instances[instance_id].private_dns_name
      end
    end

    autoscaling_dns
  end

  def fetch_autoscaling_group_instances(aws_region, autoscaling_group_name, aws_credentials)
    Aws::AutoScaling::Client.new(region: aws_region, credentials: aws_credentials)
    as.describe_auto_scaling_groups(
        auto_scaling_group_names: autoscaling_group_name,
        max_records: 1,
    ).auto_scaling_groups[0].instances
  end

end