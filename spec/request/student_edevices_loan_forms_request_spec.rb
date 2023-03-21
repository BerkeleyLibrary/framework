require 'forms_helper'

describe :student_edevices_loan_form, type: :request do
  it_behaves_like(
    'an authenticated form',
    form_class: StudentEdevicesLoanForm,
    allowed_patron_types: [
      Alma::Type::UNDERGRAD,
      Alma::Type::UNDERGRAD_SLE,
      Alma::Type::GRAD_STUDENT,
      Alma::Type::EXTENSION_STUDENT
    ],
    submit_path: '/forms/student_edevices_loan',
    success_path: '/forms/student_edevices_loan/all_checked',
    valid_form_params: {
      student_edevices_loan_form: {
        borrow_check: 'checked',
        edevices_check: 'checked',
        fines_check: 'checked',
        lending_check: 'checked'
      }
    }
  )
end
