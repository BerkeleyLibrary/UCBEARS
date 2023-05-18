source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.2.2'

gem 'awesome_print', '~> 1.9'
gem 'berkeley_library-alma', '~> 0.0.7'
gem 'berkeley_library-docker', '~> 0.2.0'
gem 'berkeley_library-logging', '~> 0.2', '>= 0.2.7'
gem 'berkeley_library-marc', '~> 0.3'
gem 'berkeley_library-util', '~> 0.1', '>= 0.1.8'
gem 'dotiw', '~> 5.3'
gem 'iiif-presentation', '~> 1.0'
gem 'jbuilder', '~> 2.5'
gem 'jwt', '~> 2.2'
gem 'listen' # TODO: what actually uses this?
gem 'lograge', '>= 0.11.2'
gem 'net-ssh'
gem 'non-stupid-digest-assets', '~> 1.0'
gem 'omniauth-cas', '~> 2.0'
gem 'pagy', '~> 5.6'
gem 'pg', '~> 1.2'
gem 'pg_search', '~> 2.3'
gem 'puma', '~> 4.3', '>= 4.3.12'
gem 'rails', '~> 7.0.4'
gem 'ruby-prof', '~> 0.17.0' # TODO: move this back to dev/test
gem 'ruby-vips', '~> 2.0'
gem 'sass-rails', '~> 6.0'
gem 'sprockets', '~> 4.0'
gem 'typesafe_enum', '~> 0.3'
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
gem 'webpacker', '~> 5.4'

group :development, :test do
  gem 'brakeman'
  gem 'bundle-audit'
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'colorize'
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 5.0'
end

group :development do
  gem 'dotenv', '~> 2.7', require: false
  gem 'rubocop', '~> 1.26.0'
  gem 'rubocop-rails', '~> 2.13.2'
  gem 'rubocop-rspec', '~> 2.4.0'
  gem 'web-console', '>= 4.1.0'
end

group :test do
  gem 'capybara', '~> 3.36'
  gem 'concurrent-ruby', '~> 1.1'
  gem 'database_cleaner-active_record', '~> 2.0'
  gem 'rspec', '~> 3.10'
  gem 'rspec_junit_formatter', '~> 0.5'
  gem 'selenium-webdriver', '~> 4.0'
  gem 'simplecov', '~> 0.21', require: false
  gem 'simplecov-rcov', '~> 0.2', require: false
  gem 'webmock', require: false
end
