require File.expand_path('../lib/localytics', File.dirname(__FILE__))
require File.expand_path('test_helper', File.dirname(__FILE__))

require 'cutest'
require 'mocha/api'
include Mocha::API

prepare do
  # Prepare Test
end

setup do
  # Setup test
end

test 'autoscale' do |mock|
  # Do Test
end