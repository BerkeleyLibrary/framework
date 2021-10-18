require 'forms_helper'

describe :galc_request_form, type: :request do
  it_behaves_like(
    'an authenticated form',
    form_class: GalcRequestForm,
    allowed_patron_types: [
      Alma::Type::UNDERGRAD,
      Alma::Type::UNDERGRAD_SLE,
      Alma::Type::GRAD_STUDENT,
      Alma::Type::FACULTY,
      Alma::Type::MANAGER,
      Alma::Type::LIBRARY_STAFF,
      Alma::Type::STAFF
    ],
    submit_path: '/forms/galc-agreement',
    success_path: '/forms/galc-agreement/confirmed',
    valid_form_params: {
      galc_request_form: {
        borrow_check: 'checked',
        fine_check: 'checked'
      }
    }
  )
end
