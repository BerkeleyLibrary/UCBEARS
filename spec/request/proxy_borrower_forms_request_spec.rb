require 'forms_helper'

describe 'Proxy Borrower Forms', type: :request do
  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  context 'specs without admin privledges' do
    before(:each) do
      @patron_id = Patron::Type.sample_id_for(Patron::Type::FACULTY)
      @user = login_as_patron(patron_id)
      @patron = Patron::Record.find(patron_id)
    end

    after(:each) do
      logout!
    end

    it 'Admin page redirects to main proxy borrower card page if user is non-admin', :non_admin do
      get forms_proxy_borrower_admin_path
      expect(response.status).to eq 302
    end

    it 'Index page renders' do
      get proxy_borrower_forms_path
      expect(response.status).to eq 200
    end
  end

  context 'specs with created admin privledges' do
    before(:each) do
      # Need to create a request for search!!!
      @req = ProxyBorrowerRequests.new(
        faculty_name: 'Test Search User',
        department: 'ABCD',
        faculty_id: '12345',
        student_name: nil,
        student_dsp: nil,
        dsp_rep: nil,
        research_last: 'RLast',
        research_first: 'RFirst',
        research_middle: nil,
        date_term: Date.tomorrow,
        renewal: 0,
        status: nil
      )

      # make sure we have a fresh set of tables:
      Assignment.delete_all
      Role.delete_all
      FrameworkUsers.delete_all

      # Create a user:
      framework_user = FrameworkUsers.create(lcasid: '333333', name: 'John Doe', role: 'Admin')

      # Create an assignment:
      Assignment.create(framework_users: framework_user, role: Role.proxyborrow_admin)

      @patron_id = Patron::Type.sample_id_for(Patron::Type::FACULTY)
      @user = login_as_patron(patron_id)
      @patron = Patron::Record.find(patron_id)

      admin_user = User.new(uid: '333333', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(ProxyBorrowerFormsController).to receive(:current_user).and_return(admin_user)
    end

    it 'Index contain disabled student links' do
      get proxy_borrower_forms_path
      expect(response.body).to include('<a href="/forms/proxy-borrower/dsp">Request Disabled Student</a>')
      expect(response.status).to eq 200
    end

    it 'Faculty Form renders for faculty members' do
      get forms_proxy_borrower_faculty_path
      expect(response.status).to eq 200
    end
  end

  context 'specs with hard-coded admin privledges' do
    before(:each) do
      # Need to create a request for search!!!
      @req = ProxyBorrowerRequests.create(
        faculty_name: 'Test Search User',
        department: 'ABCD',
        faculty_id: '12345',
        student_name: nil,
        student_dsp: nil,
        dsp_rep: nil,
        research_last: 'RLast',
        research_first: 'RFirst',
        research_middle: nil,
        date_term: Date.tomorrow,
        renewal: 0,
        status: nil
      )

      @patron_id = Patron::Type.sample_id_for(Patron::Type::FACULTY)
      @user = login_as_patron(patron_id)
      @patron = Patron::Record.find(patron_id)

      admin_user = User.new(uid: '1707532', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(ProxyBorrowerAdminController).to receive(:current_user).and_return(admin_user)
    end

    it 'DSP Form renders correct form' do
      get forms_proxy_borrower_dsp_path
      expect(response.body).to include('<h1>Proxy Borrower Card Application Form - DSP</h1>')
      expect(response.status).to eq 200
    end

    it 'Faculty Form redirects for non faculty members' do
      get forms_proxy_borrower_faculty_path
      expect(response.status).to eq 302
    end

    it 'Admin page renders' do
      get forms_proxy_borrower_admin_path
      expect(response.status).to eq 200
    end

    it 'Admin View DB page renders' do
      get forms_proxy_borrower_admin_view_path
      expect(response.status).to eq 200
    end

    it 'Admin Export redirects' do
      get forms_proxy_borrower_admin_export_path
      expect(response.status).to eq 302
    end

    it 'Admin Search renders page' do
      get forms_proxy_borrower_admin_search_path
      expect(response.status).to eq 200
    end

    it 'Admin Search indicates if there are no search results found' do
      get(forms_proxy_borrower_admin_search_path, params: {
            search_term: 'SEARCHVALUE'
          })

      expect(response.status).to eq 200
      expect(response.body).to match(/we could not find any results/)
    end

    it 'Admin Search finds a record' do
      get(forms_proxy_borrower_admin_search_path, params: {
            search_term: 'RLast'
          })

      expect(response.status).to eq 200
      expect(response.body).to match(/Test Search User/)
    end

    it 'Admin Search handles date searches' do
      get(forms_proxy_borrower_admin_search_path, params: {
            search_term: '4/13/1996'
          })

      expect(response.status).to eq 200
      expect(response.body).to match(/we could not find any results/)
    end

    it 'Admin Add/Edit Users form renders' do
      get forms_proxy_borrower_admin_users_path
      expect(response.status).to eq 200
    end

    it 'Results page renders' do
      get forms_proxy_borrower_result_path
      expect(response.status).to eq 200
    end

    it 'Faculty Form rejects a submission with missing fields' do
      post(forms_proxy_borrower_request_faculty_path, params: {
             faculty_name: 'John Doe',
             research_last: '',
             research_first: '',
             term: '',
             renewal: ''
           })

      expect(response.status).to eq 200
      expect(response.body).to match(/Please correct them before submitting the form again/)
    end
  end
end
