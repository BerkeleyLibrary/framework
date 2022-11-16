require 'forms_helper'

describe :service_article_request_forms, type: :request do

  describe 'with a "book scan eligible" note' do
    before do
      eligible_notes = ['20190101 library book scan eligible [litscript]']
      allow_any_instance_of(Alma::User).to receive(:notes).and_return(eligible_notes)
    end

    it_behaves_like(
      'an authenticated form',
      form_class: ServiceArticleRequestForm,
      allowed_patron_types: Alma::Type.all,
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

  # book scan eligible only in 99999890.txt and 99999891.txt

  # it 'requires a "book scan eligible" note' do
  #   not_eligible_notes = ['I might be eligible for some stuff but not this']
  #   allow_any_instance_of(Alma::User).to receive(:notes).and_return(not_eligible_notes)
  #   all_alma_ids.each do |patron_id|
  #     with_patron_login(patron_id) do
  #       get new_service_article_request_form_path
  #       expect(response).to have_http_status(:forbidden)
  #     end
  #   end
  # end

  it 'requires a "book scan eligible" note' do
    allow(Rails.application.config).to receive(:alma_api_key).and_return('totally-fake-key')

    not_eligible_notes = ['I might be eligible for some stuff but not this']
    allow_any_instance_of(Alma::User).to receive(:find_note).and_return(not_eligible_notes)

    with_patron_login('013191305') do
      get new_service_article_request_form_path
      expect(response).to have_http_status(:forbidden)
    end

  end

end
