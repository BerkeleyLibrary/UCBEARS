require 'forms_helper'

describe :service_article_request_forms, type: :request do

  describe 'with a "book scan eligible" note' do
    before(:each) do
      eligible_notes = ['20190101 library book scan eligible [litscript]']
      allow_any_instance_of(Patron::Record).to receive(:notes).and_return(eligible_notes)
    end

    it_behaves_like(
      'an authenticated form',
      form_class: ServiceArticleRequestForm,
      allowed_patron_types: Patron::Type.all,
      submit_path: '/forms/altmedia-articles',
      success_path: '/forms/altmedia-articles/confirmed',
      valid_form_params: {
        service_article_request_form: {
          patron_email: 'ethomas@berkeley.edu',
          display_name: 'Elissa Thomas',
          pub_title: 'A Test Publication',
          article_title: 'Exciting scholarly article title',
          vol: '3',
          citation: 'Davis, K. Exciting scholarly article title. A Test Publication: 3'
        }
      }
    )
  end

  it 'requires a "book scan eligible" note' do
    not_eligible_notes = ['I might be eligible for some stuff but not this']
    allow_any_instance_of(Patron::Record).to receive(:notes).and_return(not_eligible_notes)
    all_patron_ids.each do |patron_id|
      with_patron_login(patron_id) do
        get new_service_article_request_form_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
