lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "capistrano/autoscaling_deploy/version"

Gem::Specification.new do |spec|
  spec.name = "capistrano3-autoscaling-deploy"
  spec.version = Capistrano::AutoScalingDeploy::VERSION
  spec.authors = ["Marcos Chicote"]
  spec.email = ["chicotemarcos@gmail.com"]
  spec.summary = "Deploy to AWS Auto Scaling group."
  spec.description = "Capistrano 3 plugin that finds the in-service instances of an AWS Auto Scaling group and deploys to them."
  spec.homepage = "https://github.com/marcoschicote/capistrano3-autoscaling-deploy"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3"

  spec.metadata = {
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = `git ls-files -- lib`.split($/) + %w[README.md LICENSE CHANGELOG.md]
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk-autoscaling", "~> 1"
  spec.add_dependency "aws-sdk-ec2", "~> 1"
  spec.add_dependency "capistrano", "~> 3"
  spec.add_development_dependency "bundler", ">= 2.2.33"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "standard"
end
