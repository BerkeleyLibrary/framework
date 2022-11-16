require 'forms_helper'

describe :doemoff_study_room_use_forms, type: :request do
  it_behaves_like(
    'an authenticated form',
    form_class: DoemoffStudyRoomUseForm,
    allowed_patron_types: [
      Alma::Type::UNDERGRAD,
      Alma::Type::UNDERGRAD_SLE,
      Alma::Type::GRAD_STUDENT,
      Alma::Type::FACULTY,
      Alma::Type::MANAGER,
      Alma::Type::LIBRARY_STAFF,
      Alma::Type::STAFF,
      Alma::Type::POST_DOC,
      Alma::Type::VISITING_SCHOLAR
    ],
    submit_path: '/forms/doemoff-study-room-use',
    success_path: '/forms/doemoff-study-room-use/all_checked',
    valid_form_params: {
      doemoff_study_room_use_form: {
        borrow_check: 'checked',
        room_use_check: 'checked',
        fines_check: 'checked'
      }
    }
  )
end
