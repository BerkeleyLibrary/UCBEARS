namespace :db do
  desc 'Wait until the database is ready to accept connections'
  task await: [:environment] do
    tries = 0
    max_tries = 4
    begin
      pool ||= ActiveRecord::Base.establish_connection
      pool.connection
    rescue PG::ConnectionBad
      raise unless (tries += 1) <= max_tries

      sleep_time = 2**tries # backoff exponentially (2s, 4s, 8s, ...)
      Rails.logger.error "DB connection failed, retrying in #{sleep_time}s"
      sleep sleep_time
      retry
    rescue ActiveRecord::NoDatabaseError
      Rails.logger.warn 'Connected, but the database is missing. You might ' \
                        'want to run database setup tasks next.'
    end
  end
end
