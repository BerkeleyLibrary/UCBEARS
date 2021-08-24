require 'rails_helper'

describe SessionsController, type: :request do
  before(:each) do
    @logger_orig = Rails.logger
  end

  after(:each) do
    Rails.logger = @logger_orig
  end

  it 'logs CalNet/Omniauth parameters as JSON' do
    logdev = StringIO.new
    logger = BerkeleyLibrary::Logging::Loggers.new_json_logger(logdev)
    allow_any_instance_of(SessionsController).to receive(:logger).and_return(logger)

    user = mock_login(:staff) { get index_path }
    lines = logdev.string.lines

    expected_msg = 'Received omniauth callback'
    log_line = lines.find { |line| line.include?(expected_msg) }
    result = JSON.parse(log_line)
    expect(result['msg']).to eq(expected_msg)
    omniauth_hash = result['omniauth']
    expect(omniauth_hash['provider']).to eq('calnet') # just a smoke test
    expect(omniauth_hash['extra']['uid']).to eq(user.uid)
  end

  describe :sign_in do
    before(:each) do
      {
        lending_root_path: Pathname.new('spec/data/lending'),
        iiif_base_uri: URI.parse('http://ucbears-iiif/iiif/')
      }.each do |getter, val|
        allow(Lending::Config).to receive(getter).and_return(val)
      end
    end

    it 'persists the expected attributes in the session cookie' do
      user_from_omniauth = mock_login(:lending_admin)

      request.reset_session
      expect(session[:user]).to be_nil # just to be sure

      get(index_path)

      user_from_cookie = User.from_session(session)
      %i[uid borrower_id affiliations cal_groups].each do |attr|
        expected_value = user_from_omniauth.send(attr)
        actual_value = user_from_cookie.send(attr)
        expect(actual_value).to eq(expected_value), "Expected #{expected_value.inspect} for #{attr}, got #{actual_value.inspect}"
      end
    end
  end
end
