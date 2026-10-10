require "test_helper"

class AwsHelperTest < Minitest::Test
  include AwsHelper
  include AutoScalingStubs

  INSTANCE_IDS = %w[i-3 i-1 i-2]

  def instances(ip_type)
    get_instances("us-west-2", "key", "secret", "my-group", ip_type)
  end

  def test_returns_public_dns_names_in_auto_scaling_group_order
    stub_aws(INSTANCE_IDS)

    assert_equal %w[i-3.public.example.com i-1.public.example.com i-2.public.example.com], instances("public_dns_name")
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

    assert_equal %w[i-3.public.example.com i-1.public.example.com i-2.public.example.com], instances("elastic_ip")
  end

  def test_skips_instances_that_are_not_in_service
    stub_aws(%w[i-1 i-2 i-3 i-4], lifecycle_states: {"i-1" => "Pending", "i-3" => "Terminating", "i-4" => "Standby"})

    out, _ = capture_io do
      assert_equal %w[i-2.public.example.com], instances("public_dns_name")
    end
    assert_includes out, "Skipping i-1 (Pending)"
    assert_includes out, "Skipping i-3 (Terminating)"
  end

  def test_lifecycle_states_can_be_overridden
    stub_aws(%w[i-1 i-2], lifecycle_states: {"i-1" => "Standby"})

    result = get_instances("us-west-2", "key", "secret", "my-group", "public_dns_name", lifecycle_states: %w[InService Standby])
    assert_equal %w[i-1.public.example.com i-2.public.example.com], result
  end

  def test_missing_group_raises_a_clear_error
    Aws.config[:autoscaling] = {stub_responses: {describe_auto_scaling_groups: {auto_scaling_groups: []}}}

    error = assert_raises(RuntimeError) { instances("public_dns_name") }
    assert_equal "Auto Scaling group 'my-group' not found in us-west-2", error.message
  end

  def test_blank_addresses_raise_a_clear_error
    stub_aws(INSTANCE_IDS, overrides: {"i-1" => {public_dns_name: ""}, "i-2" => {public_dns_name: ""}})

    error = assert_raises(RuntimeError) { instances("public_dns_name") }
    assert_match(/\AInstances i-1, i-2 have no public_dns_name\. Set :aws_ip_type/, error.message)
  end

  def test_missing_addresses_raise_a_clear_error
    stub_aws(INSTANCE_IDS, overrides: {"i-3" => {public_ip_address: nil}})

    error = assert_raises(RuntimeError) { instances("public_ip_address") }
    assert_match(/\AInstances i-3 have no public_ip_address\./, error.message)
  end

  def test_empty_group_returns_no_instances
    stub_aws([])

    assert_equal [], instances("public_dns_name")
  end
end
