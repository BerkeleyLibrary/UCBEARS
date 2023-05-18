require 'rest-client'
require 'berkeley_library/util/uris'

module SystemSpecHelper
  CONTENT_TYPES = {
    html: 'text/html',
    json: 'application/json',
    csv: 'text/csv'
  }.freeze

  attr_reader :request, :response

  # Uses RestClient to make an HTTP request to the Capybara server in a way that
  # approximates a request spec rather than a system spec.
  def raw_get(url, params: {}, headers: {}, as: nil)
    uri = ensure_uri(url)
    headers_actual = headers.merge(accept_header(as))
    response = do_get_response(uri, params:, headers: headers_actual)
    @request = to_ad_request(response.request)
    @response = to_ad_response(response)
  end

  def ensure_uri(url)
    raise ArgumentError("Not a URL, URI, or path: #{url.inspect}") unless (uri = BerkeleyLibrary::Util::URIs.uri_or_nil(url))

    if uri.absolute?
      return URI.parse(uri.to_s).tap do |u|
        u.host = server_uri.host
        u.port = server_uri.port
      end
    end

    BerkeleyLibrary::Util::URIs.append(server_uri, uri.path)
  end

  private

  def accept_header(as_content_type)
    { 'Accept' => CONTENT_TYPES.fetch(as_content_type, '*/*') }
  end

  def server_uri
    @server_uri ||= URI.parse(page.server_url)
  end

  def do_get_response(uri, params:, headers:)
    url_str = url_str_with_params(uri, params)
    RestClient::Request.execute(
      method: :get,
      url: url_str,
      headers:,
      max_redirects: 0
    )
  rescue RestClient::ExceptionWithResponse => e
    e.response
  end

  # TODO: add no-redirect option to BerkeleyLibrary::Util::URIs & remove this
  def url_str_with_params(uri, params)
    url_str = uri.to_s

    elements = [].tap do |ee|
      ee << url_str
      next if params.empty?

      ee << '?' unless url_str.include?('?')
      ee << URI.encode_www_form(params)
    end

    uri = BerkeleyLibrary::Util::URIs::Appender.new(*elements).to_uri
    uri.to_s
  end

  def to_ad_request(r)
    env = r.headers.transform_keys do |k|
      upcased = k.to_s.upcase
      upcased == 'ACCEPT' ? 'HTTP_ACCEPT' : upcased
    end
    request_uri = r.uri
    env['ORIGINAL_FULLPATH'] = request_uri.path
    env['HTTP_HOST'] = request_uri.host
    env['HTTP_PORT'] = request_uri.port
    env['REQUEST_METHOD'] = r.method.upcase

    ActionDispatch::Request.new(env)
  end

  def to_ad_response(r)
    headers = r.headers.transform_keys do |k|
      ActiveSupport::Inflector.titleize(k).gsub(' ', '-')
    end

    ActionDispatch::Response.new(r.code, headers, [r.body]).tap(&:commit!)
  end

end
