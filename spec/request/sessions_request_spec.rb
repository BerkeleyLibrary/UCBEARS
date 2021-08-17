require 'calnet_helper'

describe SessionsController, type: :request do
  before(:each) do
    @logger_orig = Rails.logger
  end

  after(:each) do
    Rails.logger = @logger_orig
  end

  it 'logs CalNet/Omniauth parameters as JSON' do
    logdev = StringIO.new
    logger = UCBLIT::Logging::Loggers.new_json_logger(logdev)
    allow_any_instance_of(SessionsController).to receive(:logger).and_return(logger)

    patron_id = Patron::FRAMEWORK_ADMIN_ID
    with_patron_login(patron_id) { get admin_path }
    lines = logdev.string.lines

    expected_msg = 'Received omniauth callback'
    log_line = lines.find { |line| line.include?(expected_msg) }
    result = JSON.parse(log_line)
    expect(result['msg']).to eq(expected_msg)
    omniauth_hash = result['omniauth']
    expect(omniauth_hash['provider']).to eq('calnet') # just a smoke test
    expect(omniauth_hash['extra']['employeeNumber']).to eq(patron_id)
  end
end
