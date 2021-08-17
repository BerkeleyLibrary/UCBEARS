desc 'Run all specs in spec directory, with coverage'
task :coverage do
  ENV['COVERAGE'] ||= 'true'
  Rake::Task[:spec].invoke
end
