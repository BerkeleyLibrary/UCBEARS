require 'capybara_helper'
require 'calnet_helper'
require 'roo'

describe TindDownloadController, type: :system do
  let(:tind_base_uri) { URI('https://digicoll.lib.berkeley.edu/') }
  let(:tind_api_key) { 'not-a-real-api-key' }

  before(:each) do
    allow(UCBLIT::TIND::Config).to receive(:api_key).and_return(tind_api_key)
    allow(UCBLIT::TIND::Config).to receive(:base_uri).and_return(tind_base_uri)
  end

  describe 'unauthenticated user' do
    it 'redirects to login' do
      visit tind_download_path
      expected_path = "#{omniauth_callback_path(:calnet)}?#{URI.encode_www_form(origin: tind_download_path)}"
      expect(page).to have_current_path(expected_path)
    end
  end

  describe 'authenticated non-staff user' do
    # TODO: replace with around(:each) using with_patron_login() once we're on Rails 6.1
    #       (see CapybaraHelper::GridConfigurator#configure!)
    before(:each) { login_as_patron(Patron::Type.sample_id_for(Patron::Type::FACULTY)) }
    after(:each) { logout! }

    it 'returns 403 unauthorized' do
      visit tind_download_path
      expect(page).to have_content('Restricted to University staff')
    end
  end

  describe 'authenticated staff user' do
    # TODO: replace with around(:each) using with_patron_login() once we're on Rails 6.1
    #       (see CapybaraHelper::GridConfigurator#configure!)
    before(:each) { login_as_patron(Patron::Type.sample_id_for(Patron::Type::STAFF)) }
    after(:each) { clear_login_state! }

    before(:each) do
      stub_request(:get, UCBLIT::Util::URIs.append(tind_base_uri, 'api/v1/collections?depth=100')).to_return(
        status: 200,
        body: File.new('spec/data/tind_download/collections.json')
      )

      visit tind_download_path
    end

    it 'displays the form' do
      expect(page).to have_content('TIND Metadata Download')
    end

    describe 'download button' do
      it 'defaults to disabled' do
        expect(page).to have_button('Download Metadata', disabled: true)
      end

      it 'is enabled once a collection name is entered' do
        fill_in('collection_name', with: 'Abraham Lincoln Papers')
        expect(page).to have_button('Download Metadata', disabled: false)
      end

      describe 'downloads' do
        before(:each) do
          search_id = 'DnF1ZXJ5VGhlbkZldGNoBQAAAAABsY'
          search_url = UCBLIT::Util::URIs.append(tind_base_uri, 'api/v1/search')
          search_params = { c: 'Abraham Lincoln Papers', format: 'xml' }
          search_params_with_search_id = search_params.merge(search_id: search_id)
          result_1 = File.read('spec/data/tind_download/tind-abraham-lincoln-1.xml')
          result_2 = File.read('spec/data/tind_download/tind-abraham-lincoln-2.xml')
          stub_request(:get, search_url).with(query: search_params).to_return(status: 200, body: result_1)
          stub_request(:get, search_url).with(query: search_params_with_search_id).to_return(status: 200, body: result_2)

          fill_in('collection_name', with: 'Abraham Lincoln Papers')
        end

        UCBLIT::TIND::Export::ExportFormat.each do |fmt|
          it "downloads #{fmt}" do
            format = fmt.value.downcase

            page.choose("export_format_#{format}")
            page.click_button('Download Metadata')

            # Wait for "Your download should start" to appear
            expect(page).to have_content('Your download should start momentarily', wait: 10)

            # TODO: verify download, cf. https://www.gridlastic.com/selenium-grid-download-file.html ?
          end
        end
      end
    end
  end
end
