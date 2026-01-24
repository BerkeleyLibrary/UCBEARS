# initializers/okcomputer.rb
require 'health_checks'

OkComputer.logger = Rails.logger
OkComputer.check_in_parallel = true

# Readiness: Database reachable
OkComputer::Registry.register 'database', OkComputer::ActiveRecordCheck.new

# Check that DB migrations have run
OkComputer::Registry.register 'database-migrations', OkComputer::ActiveRecordMigrationsCheck.new

# Custom IIIF server check
OkComputer::Registry.register 'iiif-server', HealthChecks::IIIFServerCheck.new

# TODO: Custom Test Item Exists
OkComputer::Registry.register 'test-item-exists', HealthChecks::TestItemExists.new

# TODO: Custom Lending Root Path
OkComputer::Registry.register 'lending-root-path', HealthChecks::LendingRootPath.new
