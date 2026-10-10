require 'aws-sdk-autoscaling'
require 'aws-sdk-ec2'

module AwsHelper
  IP_TYPES = %w(public_ip_address public_dns_name private_ip_address private_dns_name)

  def get_instances(aws_region, aws_access_key_id, aws_secret_access_key, aws_autoscaling_group_name, aws_ip_type, aws_profile: nil)
    client_options = aws_client_options(aws_region, aws_access_key_id, aws_secret_access_key, aws_profile)
    retrieve_ec2_instances(client_options, aws_autoscaling_group_name, aws_ip_type)
  end

  # Explicit keys win, then a named profile. With neither, the SDK's default
  # credential chain is used: environment variables, shared config and
  # credentials files, SSO, and ECS or EC2 instance roles.
  def aws_client_options(aws_region, aws_access_key_id, aws_secret_access_key, aws_profile = nil)
    options = { region: aws_region }

    if aws_access_key_id && aws_secret_access_key
      options[:credentials] = Aws::Credentials.new(aws_access_key_id, aws_secret_access_key)
    elsif aws_access_key_id || aws_secret_access_key
      raise ArgumentError, 'Set both :aws_access_key_id and :aws_secret_access_key, or neither to use the default AWS credential chain'
    elsif aws_profile
      options[:profile] = aws_profile
    end

    options
  end

  private

  def retrieve_ec2_instances(client_options, autoscaling_group_name, aws_ip_type)
    instances = fetch_autoscaling_group_instances(client_options, autoscaling_group_name)

    if instances.empty?
      autoscaling_dns = []
    else
      instance_ids = instances.map(&:instance_id)
      ec2 = Aws::EC2::Client.new(client_options)
      # info("Auto Scaling Group instances ids: #{instance_ids}")
      aws_ip_type = 'public_dns_name' unless IP_TYPES.include? aws_ip_type

      ec2_instances = ec2.describe_instances(instance_ids: instance_ids).flat_map do |page|
        page.reservations.flat_map(&:instances)
      end.to_h { |instance| [instance.instance_id, instance] }

      # Keep the Auto Scaling group's order: the first instance gets the primary roles
      autoscaling_dns = instance_ids.map do |instance_id|
        ec2_instances.fetch(instance_id).send(aws_ip_type.to_sym)
      end
    end

    autoscaling_dns
  end

  def fetch_autoscaling_group_instances(client_options, autoscaling_group_name)
    as = Aws::AutoScaling::Client.new(client_options)
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
