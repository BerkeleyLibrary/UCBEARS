require 'forms_helper'

describe TindDownloadController, type: :request do
  let(:collection_name) { 'Abraham Lincoln Papers' }

  let(:tind_base_uri) { URI('https://digicoll.lib.berkeley.edu/') }
  let(:tind_api_key) { 'not-a-real-api-key' }

  before(:each) do
    allow(UCBLIT::TIND::Config).to receive(:api_key).and_return(tind_api_key)
    allow(UCBLIT::TIND::Config).to receive(:base_uri).and_return(tind_base_uri)
  end

  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  context 'specs for unauthenticated user' do
    before(:each) do
      logout! # just to be sure
    end

    describe 'form' do
      it 'redirects to login' do
        get(form_path = tind_download_path)
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: form_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end

    describe 'find_collection' do
      it 'redirects to login' do
        get tind_download_find_collection_path
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: tind_download_find_collection_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end

    describe 'download' do
      it 'POST redirects to login' do
        post tind_download_download_path, params: { collection_name: collection_name, export_format: 'csv' }
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: tind_download_download_path)}"
        expect(response).to redirect_to(login_with_callback_url)
      end

      it 'GET redirects to login' do
        params = { collection_name: collection_name, export_format: 'csv' }
        get tind_download_download_path, params: params

        callback_url = "#{tind_download_download_path}?#{URI.encode_www_form(params)}"
        login_with_callback_url = "#{login_path}?#{URI.encode_www_form(url: callback_url)}"
        expect(response).to redirect_to(login_with_callback_url)
      end
    end
  end

  context 'specs for non-staff user' do
    around(:each) do |example|
      patron_id = Patron::Type.sample_id_for(Patron::Type::FACULTY)
      with_patron_login(patron_id) { example.run }
    end

    describe 'form' do
      it 'returns 403' do
        get tind_download_path
        expect(response.status).to eq(403)
      end
    end

    describe 'find_collection' do
      it 'returns 403' do
        get tind_download_find_collection_path
        expect(response.status).to eq(403)
      end
    end

    describe 'download' do
      it 'returns 403 for a POST' do
        post tind_download_download_path, params: { collection_name: collection_name, export_format: 'csv' }
        expect(response.status).to eq(403)
      end

      it 'returns 403 for a GET' do
        get tind_download_download_path, params: { collection_name: collection_name, export_format: 'csv' }
        expect(response.status).to eq(403)
      end
    end
  end

  context 'specs for staff user' do
    around(:each) do |example|
      patron_id = Patron::Type.sample_id_for(Patron::Type::STAFF)
      with_patron_login(patron_id) { example.run }
    end

    before(:each) do
      stub_request(:get, 'https://digicoll.lib.berkeley.edu/api/v1/collections?depth=100').to_return(
        status: 200,
        body: File.new('spec/data/tind_download/collections.json')
      )
    end

    describe 'form' do
      it 'is displayed' do
        get tind_download_path
        expect(response.status).to eq 200
        expect(response.body).to include('TIND Metadata Download')
      end
    end

    describe 'find_collection' do
      it 'requires a collection' do
        expect { get tind_download_find_collection_path }.to raise_error(ActionController::ParameterMissing)
      end

      it 'returns the matching collection name list' do
        get tind_download_find_collection_path, params: { collection_name: 'Abraham' }
        expect(response.status).to eq 200
        result = JSON.parse(response.body)
        expect(result).to be_a(Array)
        expect(result).to contain_exactly('Abraham Lincoln Papers', 'Veterans of the Abraham Lincoln Brigade')
      end

      it 'returns an empty list for an unmatched name' do
        get tind_download_find_collection_path, params: { collection_name: 'axolotl' }
        expect(response.status).to eq 200
        result = JSON.parse(response.body)
        expect(result).to be_a(Array)
        expect(result).to be_empty
      end
    end

    describe 'download' do
      describe 'valid collection' do

        before(:each) do
          search_url = 'https://digicoll.lib.berkeley.edu/api/v1/search'
          search_params = { c: collection_name, format: 'xml' }
          search_params_with_search_id = search_params.merge(search_id: 'DnF1ZXJ5VGhlbkZldGNoBQAAAAABsY')
          result_1 = File.read('spec/data/tind_download/tind-abraham-lincoln-1.xml')
          result_2 = File.read('spec/data/tind_download/tind-abraham-lincoln-2.xml')
          stub_request(:get, search_url).with(query: search_params).to_return(status: 200, body: result_1)
          stub_request(:get, search_url).with(query: search_params_with_search_id).to_return(status: 200, body: result_2)
        end

        def verify_ods(expected_path, body)
          Dir.mktmpdir(File.basename(__FILE__, 'rb')) do |dir|
            actual_path = File.join(dir, File.basename(expected_path))
            File.binwrite(actual_path, body)

            ss_expected = Roo::Spreadsheet.open(expected_path, file_warning: :warning)
            ss_actual = Roo::Spreadsheet.open(actual_path, file_warning: :warning)

            first_column, first_row, last_column, last_row = verify_row_geometry(ss_actual, ss_expected)

            aggregate_failures(:values) do
              (first_row..last_row).each do |row|
                (first_column..last_column).each do |col|
                  verify_value(ss_actual, row, col, ss_expected)
                end
              end
            end
          end
        end

        def verify_csv(expected_path, body)
          expected = File.read(expected_path, encoding: 'UTF-8')
          expect(body).to eq(expected)
        end

        def verify_row_geometry(ss_actual, ss_expected)
          row_and_col_attrs = %i[first_row first_column last_row last_column]

          row_and_col_attrs.each do |attr|
            expected = ss_expected.send(attr)
            actual = ss_actual.send(attr)
            expect(actual).to eq(expected), "Expected #{attr} to be #{expected}, but was #{actual}"
          end

          first_row, first_column, last_row, last_column = row_and_col_attrs.map { |attr| ss_expected.send(attr) }
          [first_column, first_row, last_column, last_row]
        end

        def verify_value(ss_actual, row, col, ss_expected)
          expected_value = ss_expected.cell(row, col)
          actual_value = ss_actual.cell(row, col)
          msg = -> { "Expected value at (#{[row, col].join(', ')}) to be #{expected_value.inspect}, but was #{actual_value.inspect}" }
          expect(actual_value).to eq(expected_value), msg
        end

        UCBLIT::TIND::Export::ExportFormat.each do |fmt|
          describe fmt do
            let(:ext) { fmt.value.downcase }
            let(:expected_filename) { "abraham-lincoln-papers.#{ext}" }
            let(:expected_path) { File.join('spec/data/tind_download', expected_filename) }
            let(:verify_method) { "verify_#{ext}".to_sym }

            it 'supports POST' do
              post tind_download_download_path, params: { collection_name: collection_name, export_format: ext }
              expect(response.status).to eq(200)

              send(verify_method, expected_path, body)
            end

            it 'supports GET' do
              get tind_download_download_path, params: { collection_name: collection_name, export_format: ext }
              expect(response.status).to eq(200)

              send(verify_method, expected_path, body)
            end

          end
        end
      end

      describe 'invalid collection' do
        let(:invalid_collection) { 'Not a collection' }

        before(:each) do
          search_url = 'https://digicoll.lib.berkeley.edu/api/v1/search'
          search_params = { c: invalid_collection, format: 'xml' }
          body = File.read('spec/data/tind_download/tind-not-a-collection.json')
          stub_request(:get, search_url).with(query: search_params)
            .to_return(status: 500, body: body, headers: { 'Content-Type' => 'applicaton/json' })
        end

        UCBLIT::TIND::Export::ExportFormat.each do |fmt|
          let(:ext) { fmt.value.downcase }
          let(:params) { { collection_name: invalid_collection, export_format: ext } }

          describe fmt do
            it 'GET returns 404' do
              get tind_download_download_path, params: { collection_name: invalid_collection, export_format: ext }
              expect(response.status).to eq(404)
            end

            it 'POST returns 404' do
              post tind_download_download_path, params: { collection_name: invalid_collection, export_format: ext }
              expect(response.status).to eq(404)
            end
          end
        end
      end

    end
  end
end
