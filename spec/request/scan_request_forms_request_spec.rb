require 'forms_helper'

describe :scan_request_forms, type: :request do
  it_behaves_like(
    'an authenticated form',
    form_class: ScanRequestForm,
    allowed_patron_types: [
      Alma::Type::FACULTY,
      Alma::Type::STAFF,
      Alma::Type::LIBRARY_STAFF,
      Alma::Type::MANAGER,
      Alma::Type::VISITING_SCHOLAR
    ],
    submit_path: '/forms/altmedia',
    success_path: '/forms/altmedia/optin',
    valid_form_params: {
      scan_request_form: {
        patron_name: 'Jane Doe',
        patron_email: 'jrdoe@berkeley.test',
        opt_in: 'true'
      }
    }
  )
end
