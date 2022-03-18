require 'rails_helper'

describe SessionsController, type: :request do
  before do
    {
      lending_root_path: Pathname.new('spec/data/lending'),
      iiif_base_uri: URI.parse('http://iipsrv.test/iiif/')
    }.each do |getter, val|
      allow(Lending::Config).to receive(getter).and_return(val)
    end
  end

  it 'logs CalNet/Omniauth parameters as JSON' do
    logdev = StringIO.new
    logger = BerkeleyLibrary::Logging::Loggers.new_json_logger(logdev)
    allow_any_instance_of(SessionsController).to receive(:logger).and_return(logger)

    user = mock_login(:staff) { get root_path }
    lines = logdev.string.lines

    expected_msg = 'Received omniauth callback'
    log_line = lines.find { |line| line.include?(expected_msg) }
    result = JSON.parse(log_line)
    expect(result['msg']).to eq(expected_msg)
    omniauth_hash = result['omniauth']
    expect(omniauth_hash['provider']).to eq('calnet') # just a smoke test
    expect(omniauth_hash['extra']['uid']).to eq(user.uid)
  end

  it "increments the user's session count" do
    uid = uid_for(:staff)
    count_before = ((counter = SessionCounter.find_by(uid: uid, staff: true)) && counter.count) || 0

    mock_login(:staff)
    counter = SessionCounter.find_by(uid: uid)
    expect(counter.staff?).to eq(true)
    expect(counter.count).to eq(count_before + 1)
  end

  describe :sign_in do
    it 'persists the expected attributes in the session cookie' do
      user_from_omniauth = mock_login(:lending_admin)

      request.reset_session
      expect(session[:user]).to be_nil # just to be sure

      get(root_path)

      user_from_cookie = User.from_session(session)
      User::SESSION_ATTRS.each do |attr|
        expected_value = user_from_omniauth.send(attr)
        actual_value = user_from_cookie.send(attr)
        expect(actual_value).to eq(expected_value), "Expected #{expected_value.inspect} for #{attr}, got #{actual_value.inspect}"
      end
    end
  end

  describe :destroy do
    it 'clears the user from the session' do
      user_from_omniauth = mock_login(:lending_admin)
      expect(user_from_omniauth).to be_authenticated # just to be sure
      expect(user_from_omniauth).to be_lending_admin # just to be sure

      get logout_path
      expect(response).to redirect_to(cas_logout_url)

      user_from_cookie = User.from_session(session)
      expect(user_from_cookie).not_to be_authenticated
      expect(user_from_cookie).not_to be_lending_admin
    end
  end
end
