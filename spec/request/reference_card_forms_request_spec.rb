require 'forms_helper'

describe 'Reference Card Form', type: :request do
  attr_reader :patron_id
  attr_reader :patron
  attr_reader :user

  context 'specs without admin privledges' do
    before(:each) do
      login_as_patron(5_551_212)
    end

    it 'reference card index page redirects to form' do
      get reference_card_forms_path
      expect(response.status).to eq 302
      expect(response).to redirect_to(action: :new)
    end

    it 'redirects to login if if user is not a stack pass admin' do
      form = ReferenceCardForm.create(id: 1, email: 'openreq@test.com', name: 'John Doe',
                                      pass_date: Date.current, pass_date_end: 1.day.from_now)
      get(form_path = reference_card_form_path(id: form.id))
      expect(response).to redirect_to("#{login_path}?#{URI.encode_www_form(url: form_path)}")
    end

    it 'rejects a submission with a captcha verification error' do
      expect_any_instance_of(Recaptcha::Verify).to receive(:verify_recaptcha).and_raise(Recaptcha::RecaptchaError)
      params = {
        reference_card_form: {
          email: 'jrdoe@affiliate.test',
          name: 'Jane R. Doe',
          affiliation: 'nowhere',
          research_desc: 'research goes here....',
          pass_date: '04/13/1996',
          pass_date_end: '04/15/1996',
          local_id: '123456789'
        }
      }
      post('/forms/reference-card', params: params)
      expect(response).to redirect_to(action: :new, params: params)
      get response.header['Location']
      expect(response.body).to match('RECaptcha Error')
    end

  end

  context 'specs with admin privledges' do
    before(:each) do
      admin_user = User.new(display_name: 'Test Admin', uid: '1707532', affiliations: ['EMPLOYEE-TYPE-ACADEMIC'])
      allow_any_instance_of(ReferenceCardFormsController).to receive(:current_user).and_return(admin_user)
      allow_any_instance_of(StackRequestsController).to receive(:current_user).and_return(admin_user)
    end

    it 'renders process form for unprocessed request' do
      form = ReferenceCardForm.create(id: 1, email: 'openreq@test.com', name: 'John Doe',
                                      pass_date: Date.current, pass_date_end: 1.day.from_now,
                                      research_desc: 'This is research', affiliation: 'Affiliation 1',
                                      local_id: '8675309')
      get "/forms/reference-card/#{form.id}"
      expect(response.body).to include('<h3>This Reference Card request needs to be processed.</h3>')
    end

    it 'renders processed page for processed request' do
      form = ReferenceCardForm.create(
        email: 'closedreq@test.com', name: 'Jane Doe',
        pass_date: Date.current, pass_date_end: 1.day.from_now,
        research_desc: 'This is research', affiliation: 'Affiliation 1',
        local_id: '8675309',
        approvedeny: true, processed_by: 'Test Admin'
      )
      get "/forms/reference-card/#{form.id}"
      expect(response.body).to include('<h2>This request has been processed</h2>')
    end

    it 'renders 404 if request does not exist' do
      get(path = '/forms/reference-card/does-not-exist')
      expect(response.status).to eq(404)
      expect(response.body).to include(path)
    end

    it 'allows an admin to deny a request' do
      form = ReferenceCardForm.create(email: 'openreq@test.com', name: 'John Doe',
                                      affiliation: 'Red Bull', pass_date: Date.current, pass_date_end: 1.day.from_now, local_id: '8675309')

      params = {
        'stack_pass_[approve_deny]' => false,
        'processed_by' => 'ADMIN USER',
        'denial_reason' => 'Item listed at another library'
      }
      patch("/forms/reference-card/#{form.id}", params: params)
      expect(response).to redirect_to(action: :show, id: 1)

      get(response.headers['Location'])
      expect(response.body).to include(params['denial_reason'])
      expect(response.body).to include('This request has been processed')
    end

  end

end
