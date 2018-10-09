require 'test_helper'

class UcopBorrowRequestFormTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def test_validations
    [
      {
        valid: false,
        attributes: {},
        errors: {
          department_head_email: ["can't be blank", "is invalid"],
          department_name: ["can't be blank"],
          employee_email: ["can't be blank", "is invalid"],
          employee_name: ["can't be blank"],
          employee_personal_email: ["can't be blank", "is invalid"],
          employee_phone: ["can't be blank"],
        },
      },
      {
        valid: false,
        attributes: {
          department_head_email: 'not an email',
          department_name: '',
          employee_email: 'not an email',
          employee_name: '',
          employee_personal_email: 'not an email',
          employee_phone: '',
        },
        errors: {
          department_head_email: ["is invalid"],
          department_name: ["can't be blank"],
          employee_email: ["is invalid"],
          employee_name: ["can't be blank"],
          employee_personal_email: ["is invalid"],
          employee_phone: ["can't be blank"],
        },
      },
      {
        valid: true,
        attributes: {
          department_head_email: 'email@mail.com',
          department_name: 'not blank',
          employee_email: 'email@mail.com',
          employee_name: 'not blank',
          employee_personal_email: 'email@mail.com',
          employee_phone: 'not blank',
        },
        errors: {
          department_head_email: [],
          department_name: [],
          employee_email: [],
          employee_name: [],
          employee_personal_email: [],
          employee_phone: [],
        },
      },
    ].each do |attributes:, errors:, valid:|
      form = UcopBorrowRequestForm.new(attributes)

      assert_same valid, form.valid?

      if not valid
        assert_raises ActiveModel::ValidationError do
          form.submit!
        end
      end

      errors.each do |attr_name, attr_errs|
        assert_equal form.errors[attr_name], attr_errs
      end
    end
  end

  def test_sends_ucop_borrow_email
    assert_emails 1 do
      form = UcopBorrowRequestForm.new(
        department_head_email: 'jeff@wilco.com',
        department_name: "Beat Keepin'",
        employee_email: 'glenn@wilco.com',
        employee_name: 'Glenn Kotche',
        employee_personal_email: 'glenn@gmail.com',
        employee_phone: '1(773)009-4526',
      )
      form.submit!
    end

    assert_email RequestMailer.deliveries.last,
      subject: 'UC Berkeley Borrowing Card Requested',
      to: ['jeff@wilco.com']
  end
end
