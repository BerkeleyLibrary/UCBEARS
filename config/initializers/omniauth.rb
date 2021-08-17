Rails.application.config.middleware.use OmniAuth::Builder do
  # The "developer" strategy is a dummy strategy used in testing. To use it,
  # start the app and visit /auth/developer. You'll be presented with a form
  # that allows you to enter the listed User attributes.
  unless Rails.env.production?
    provider :developer,
             fields: %i[uid display_name employee_id],
             uid_field: :uid
  end

  cas_host = ENV.fetch('CAS_HOST') do
    "auth#{'-test' unless Rails.env.production?}.berkeley.edu"
  end

  fetch_raw_info = proc do |_strategy, _opts, _ticket, _user_info, rawxml|
    next {} if rawxml.empty?

    groups_txt = rawxml.xpath('//cas:berkeleyEduIsMemberOf').map(&:text)
    affiliations_txt = rawxml.xpath('//cas:berkeleyEduAffiliations').map(&:text)

    { 'berkeleyEduIsMemberOf' => groups_txt, 'berkeleyEduAffiliations' => affiliations_txt }
  end

  provider :cas,
           name: :calnet,
           host: cas_host,
           login_url: '/cas/login',
           service_validate_url: '/cas/p3/serviceValidate',
           fetch_raw_info: fetch_raw_info

  # Override the default 'puts' logger that Omniauth uses.
  OmniAuth.config.logger = Rails.logger
end
