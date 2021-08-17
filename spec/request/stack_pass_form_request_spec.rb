require 'forms_helper'

describe 'Stack Pass Form', type: :request do
  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  context 'specs without admin privledges' do
    before(:each) do
      login_as_patron(5_551_212)
    end

    it 'index page does not include admin link for non admins' do
      get stack_requests_path
      expect(response.body).not_to include('Admin User')
    end

    it 'stackpass index page redirects to form' do
      get stack_pass_forms_path
      expect(response).to redirect_to(action: :new)
    end

    it 'redirects to login if if user is not a stack pass admin' do
      form = StackPassForm.create(email: 'openreq@test.com', name: 'John Doe',
                                  phone: '925-555-1234', pass_date: Date.current, main_stack: true)

      get((form_path = stack_pass_form_path(id: form.id)))
      expect(response).to redirect_to("#{login_path}?#{URI.encode_www_form(url: form_path)}")
    end

    it 'rejects a submission with a captcha verification error' do
      expect_any_instance_of(Recaptcha::Verify).to receive(:verify_recaptcha).and_raise(Recaptcha::RecaptchaError)

      params = {
        stack_pass_form: {
          email: 'jrdoe@affiliate.test',
          name: 'Jane R. Doe',
          phone: '925-555-1212',
          stack_pass_form_main_stack: true,
          pass_date: '04/13/1996',
          local_id: '123456789'
        }
      }
      post('/forms/stack-pass', params: params)
      expect(response).to redirect_to(action: :new, params: params)
      get response.header['Location']
      expect(response.body).to match('RECaptcha Error')
    end

  end

  context 'specs with admin privledges' do
    before(:each) do
      admin_user = User.new(display_name: 'Test Admin', uid: '1707532', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(StackPassFormsController).to receive(:current_user).and_return(admin_user)
      allow_any_instance_of(StackRequestsController).to receive(:current_user).and_return(admin_user)
    end

    it 'index page renders' do
      get stack_requests_path
      expect(response.status).to eq 200
      expect(response.body).to include('Admin User')
    end

    it 'renders process form for unprocessed request' do
      form = StackPassForm.create(email: 'openreq@test.com', name: 'John Doe',
                                  phone: '925-555-1234', pass_date: Date.current, main_stack: true, local_id: '8675309')
      get "/forms/stack-pass/#{form.id}"
      expect(response.body).to include('<h3>This request needs to be processed.</h3>')
    end

    it 'renders processed page for processed request' do
      form = StackPassForm.create(email: 'closedreq@test.com', name: 'Jane Doe',
                                  phone: '925-555-5678', pass_date: Date.current, main_stack: true, local_id: '8675309',
                                  approvedeny: true, processed_by: 'Test Admin')
      get "/forms/stack-pass/#{form.id}"
      expect(response.body).to include('<h2>This request has been processed</h2>')
    end

    it 'renders 404 if request does not exist' do
      get(path = '/forms/stack-pass/does-not-exist')
      expect(response.status).to eq(404)
      expect(response.body).to include(path)
    end

    it 'allows an admin to deny a request' do
      form = StackPassForm.create(email: 'openreq@test.com', name: 'John Doe',
                                  phone: '925-555-1234', pass_date: Date.current, main_stack: true, local_id: '8675309')

      params = {
        'stack_pass_[approve_deny]' => false,
        'processed_by' => 'ADMIN USER',
        'denial_reason' => 'Item listed at another library'
      }
      patch("/forms/stack-pass/#{form.id}", params: params)
      expect(response).to redirect_to(action: :show, id: 1)

      get(response.headers['Location'])
      expect(response.body).to include(params['denial_reason'])
      expect(response.body).to include('This request has been processed')
    end

  end

  context 'specs with hard-coded admin privledges' do

    before(:each) do |_test|
      admin_user = User.new(uid: '1707532', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(StackPassAdminController).to receive(:current_user).and_return(admin_user)
      allow_any_instance_of(StackRequestsController).to receive(:current_user).and_return(admin_user)
    end

    it 'Admin page renders' do
      get forms_stack_pass_admin_path
      expect(response.status).to eq 200
    end

    it 'Stack Pass views page renders' do
      get forms_stack_pass_admin_stack_passes_path
      expect(response.status).to eq 200
    end

    it 'Reference Card views page renders' do
      get forms_stack_pass_admin_reference_cards_path
      expect(response.status).to eq 200
    end

    it 'Admin Add/Edit Users form renders' do
      get forms_stack_pass_admin_users_path
      expect(response.status).to eq 200
    end

  end

  context 'specs with non-admin user logged in' do

    before(:each) do
      @patron_id = Patron::Type.sample_id_for(Patron::Type::FACULTY)
      @user = login_as_patron(patron_id)
      @patron = Patron::Record.find(patron_id)
    end

    it 'Admin page redirects to if user is non-admin', :non_admin do
      get forms_stack_pass_admin_path
      expect(response.status).to eq 302
    end
  end

  context 'specs with user created administrators' do
    before(:each) do |_test|
      # Create the role, user and assignment:
      Role.create(id: 1, role: 'stackpass_admin')
      admin_user = User.new(uid: '9999999', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      FrameworkUsers.create(id: 1, lcasid: '9999999', name: 'Test Dude', role: 'admin')
      Assignment.create(id: 1, framework_users_id: 1, role_id: 1)

      allow_any_instance_of(StackPassAdminController).to receive(:current_user).and_return(admin_user)
      allow_any_instance_of(StackRequestsController).to receive(:current_user).and_return(admin_user)
    end

    after(:each) do
      Assignment.delete_all
      Role.delete_all
      FrameworkUsers.delete_all
    end

    it 'admin page renders' do
      get forms_stack_pass_admin_path
      expect(response.status).to eq 200
    end

    it 'index page includes admin link for admins' do
      get stack_requests_path
      expect(response.body).to include('Admin User')
    end
  end

end
