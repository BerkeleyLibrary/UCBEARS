desc 'Security check via brakeman'
task :brakeman do |_t, _args|
  require 'brakeman'

  Brakeman.run app_path: '.',
               config_file: 'config/brakeman.yml',
               print_report: true
end
