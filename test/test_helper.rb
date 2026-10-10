require 'minitest/autorun'
require 'capistrano/all'
require 'capistrano/setup'
require 'capistrano/deploy'
require 'capistrano/autoscaling_deploy'

Aws.config[:stub_responses] = true

module AutoScalingStubs
  # Fake AWS responses. EC2 returns the instances out of order, over two pages,
  # to check that results follow the Auto Scaling group's order.
  def stub_aws(instance_ids)
    Aws.config[:autoscaling] = {
      stub_responses: {
        describe_auto_scaling_groups: {
          auto_scaling_groups: [{
            auto_scaling_group_name: 'my-group',
            min_size: 0,
            max_size: 10,
            desired_capacity: instance_ids.size,
            default_cooldown: 300,
            availability_zones: ['us-west-2a'],
            health_check_type: 'EC2',
            created_time: Time.now,
            instances: instance_ids.map do |id|
              {
                instance_id: id,
                availability_zone: 'us-west-2a',
                lifecycle_state: 'InService',
                health_status: 'Healthy',
                protected_from_scale_in: false
              }
            end
          }]
        }
      }
    }

    ec2_instances = instance_ids.reverse.map { |id| ec2_instance(id) }
    first_page, second_page = ec2_instances.partition.with_index { |_, i| i < (ec2_instances.size + 1) / 2 }
    Aws.config[:ec2] = {
      stub_responses: {
        describe_instances: [
          { reservations: [{ instances: first_page }], next_token: 'page-2' },
          { reservations: [{ instances: second_page }] }
        ]
      }
    }
  end

  def ec2_instance(id)
    {
      instance_id: id,
      public_dns_name: "#{id}.public.example.com",
      public_ip_address: "203.0.113.#{id[-1]}",
      private_dns_name: "#{id}.internal.example.com",
      private_ip_address: "10.0.0.#{id[-1]}"
    }
  end
end
