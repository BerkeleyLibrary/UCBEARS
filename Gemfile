source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '~> 3.0.0'

gem 'awesome_print', '>=1.8.0'
gem 'berkeley_library-alma', '~> 0.0.1', '>= 0.0.3'
gem 'berkeley_library-logging', '~> 0.2', '>= 0.2.3'
gem 'berkeley_library-marc', '~> 0.2'
gem 'berkeley_library-util', '~> 0.1.1'
gem 'dotiw'
gem 'iiif-presentation', '~> 1.0'
gem 'jbuilder', '~> 2.5'
gem 'jwt', '~> 2.2'
gem 'listen' # TODO: what actually uses this?
gem 'lograge', '>=0.11.2'
gem 'net-ssh'
gem 'non-stupid-digest-assets'
gem 'omniauth-cas', '~> 2.0'
gem 'ougai', '>=1.8.2'
gem 'pagy', '~> 5.6'
gem 'pg', '~> 1.2'
gem 'pg_search', '~> 2.3'
gem 'puma', '~> 4.3', '>= 4.3.8'
gem 'rails', '~> 6.1.4'
gem 'ruby-prof', '~> 0.17.0' # TODO: move this back to dev/test
gem 'ruby-vips', '~> 2.0'
gem 'sass-rails', '~> 6.0'
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
  gem 'rubocop-rails', '~> 2.13'
  gem 'rubocop-rspec', '~> 2.2'
  gem 'web-console', '>= 4.1.0'
end

group :test do
  gem 'capybara'
  gem 'concurrent-ruby', '~> 1.1'
  gem 'database_cleaner-active_record', '~> 2.0'
  gem 'rspec', '~> 3.10'
  gem 'rspec_junit_formatter'
  gem 'selenium-webdriver'
  gem 'simplecov', '~> 0.21', require: false
  gem 'simplecov-rcov', '~> 0.2', require: false
  gem 'webmock', require: false
end
