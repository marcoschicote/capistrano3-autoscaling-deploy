# AGENTS.md

Capistrano 3 plugin, published to RubyGems, that finds the in-service instances of an AWS Auto Scaling group and adds them as Capistrano servers. The README is for users; this file is for working on the code.

## Layout

- `lib/capistrano/autoscaling_deploy.rb`: entry point users require from their Capfile. Loads the tasks.
- `lib/capistrano/tasks/autoscaling.rake`: setting defaults (`load:defaults`), the hook before `deploy:starting`, and `autoscaling_deploy:setup_instances`, which registers the servers and assigns roles.
- `lib/capistrano/helpers/aws_helper.rb`: AWS calls. Builds client options from the credential settings, reads the group, filters by lifecycle state and reads each instance's address.
- `lib/capistrano/helpers/cap_helper.rb`: role helpers. Only the first instance keeps `:db` and `primary`.
- `lib/capistrano/autoscaling_deploy/version.rb`: gem version.

## Tests

```sh
bundle install
bundle exec rake test       # tests
bundle exec rake standard   # Standard Ruby style check (standardrb --fix to fix)
bundle exec rake            # both, as CI does
```

- Ruby 3.3 or newer. CI runs the tests on Ruby 3.3, 3.4 and 4.0 and Standard on 3.3 (`.github/workflows/test.yml`). CodeQL also runs on every pull request. These six checks are required to merge into `main`.
- Tests must never call AWS. They use the SDK's `stub_responses` through `stub_aws` in `test/test_helper.rb`, which also sets `AWS_EC2_METADATA_DISABLED`. Credential tests isolate `~/.aws` and reset the SDK's cached shared config.
- Task tests run the real Capistrano tasks: they reset `Capistrano::Configuration` and re-enable the Rake tasks in `setup`.
- For a bug fix, write the failing test first, and check that it fails without the fix.
- Ruby warnings from net-ssh and Capistrano during the test run are expected.
- CodeQL (`.github/workflows/codeql.yml`) scans the Ruby code and the workflows on every PR and weekly. Results are under Security → Code scanning; it isn't a required check.
- OpenSSF Scorecard (`.github/workflows/scorecard.yml`) runs on pushes to `main` and weekly, and publishes the score shown on scorecard.dev. When publishing, the action only accepts workflows made of approved steps, so don't add `run:` steps or other actions to that workflow.

## Conventions

- One issue per pull request, with `Closes #N` in the description.
- User-facing changes go under `## Unreleased` in `CHANGELOG.md`.
- Breaking changes also need a note in the README's "Upgrading" section.
- New or changed settings go in the README's Settings table, with their default.
- Keep the runtime dependencies to `capistrano`, `aws-sdk-autoscaling` and `aws-sdk-ec2`.
- Pin GitHub Actions to a full commit SHA with the version in a comment (`uses: actions/checkout@<sha> # v7.0.1`). Dependabot updates both monthly.

## Releasing

Publishing is done by the manual **Release** workflow (`.github/workflows/release.yml`), using RubyGems trusted publishing. It runs the tests, then `rake release`, which pushes the `vX.Y.Z` tag and publishes the gem.

Never run the Release workflow, push tags, or publish to RubyGems without explicit approval from the maintainer. Preparing a release (version bump in `version.rb` and moving `Unreleased` in `CHANGELOG.md` to the new version) goes through a normal pull request.
