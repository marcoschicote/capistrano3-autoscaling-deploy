require 'test_helper'

class AwsHelperTest < Minitest::Test
  include AwsHelper
  include AutoScalingStubs

  INSTANCE_IDS = %w(i-3 i-1 i-2)

  def instances(ip_type)
    get_instances('us-west-2', 'key', 'secret', 'my-group', ip_type)
  end

  def test_returns_public_dns_names_in_auto_scaling_group_order
    stub_aws(INSTANCE_IDS)

    assert_equal %w(i-3.public.example.com i-1.public.example.com i-2.public.example.com), instances('public_dns_name')
  end

  def test_supports_every_ip_type
    AwsHelper::IP_TYPES.each do |ip_type|
      stub_aws(INSTANCE_IDS)

      expected = INSTANCE_IDS.map { |id| ec2_instance(id).fetch(ip_type.to_sym) }
      assert_equal expected, instances(ip_type), ip_type
    end
  end

  def test_unknown_ip_type_falls_back_to_public_dns_name
    stub_aws(INSTANCE_IDS)

    assert_equal %w(i-3.public.example.com i-1.public.example.com i-2.public.example.com), instances('elastic_ip')
  end

  def test_empty_group_returns_no_instances
    stub_aws([])

    assert_equal [], instances('public_dns_name')
  end
end
