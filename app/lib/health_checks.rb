module HealthChecks
  Dir[File.join(__dir__, 'health_checks', '*.rb')].each { |f| require f }
end
