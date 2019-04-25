require 'test_helper'

class UcopBorrowRequestFormTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def test_validations
    [
      {
        valid: false,
        attributes: {},
        errors: {
          department_head_email: ["can't be blank", "is not a valid email address"],
          department_name: ["can't be blank"],
          employee_email: ["can't be blank", "is not a valid email address"],
          employee_id: ["can't be blank"],
          employee_name: ["can't be blank"],
          employee_personal_email: ["can't be blank", "is not a valid email address"],
          employee_phone: ["can't be blank"],
          employee_address: ["can't be blank"],
        },
      },
      {
        valid: false,
        attributes: {
          department_head_email: 'not an email',
          department_name: '',
          employee_email: 'not an email',
          employee_id: '',
          employee_name: '',
          employee_personal_email: 'not an email',
          employee_phone: '',
          employee_address: '',
        },
        errors: {
          department_head_email: ["is not a valid email address"],
          department_name: ["can't be blank"],
          employee_email: ["is not a valid email address"],
          employee_id: ["can't be blank"],
          employee_name: ["can't be blank"],
          employee_personal_email: ["is not a valid email address"],
          employee_phone: ["can't be blank"],
          employee_address: ["can't be blank"],
        },
      },
      {
        valid: true,
        attributes: {
          department_head_email: 'email@mail.com',
          department_name: 'not blank',
          employee_email: 'email@mail.com',
          employee_id: '12345',
          employee_name: 'not blank',
          employee_personal_email: 'email@mail.com',
          employee_phone: 'not blank',
          employee_address: 'not blank',
        },
        errors: {
          department_head_email: [],
          department_name: [],
          employee_email: [],
          employee_id: [],
          employee_name: [],
          employee_personal_email: [],
          employee_phone: [],
          employee_address: [],
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
        assert_equal attr_errs, form.errors[attr_name],
          "#{attr_name} didn't have expected errors"
      end
    end
  end

  def test_sends_ucop_borrow_email
    assert_emails 1 do
      form = UcopBorrowRequestForm.new(
        department_head_email: 'jeff@wilco.com',
        department_name: "Beat Keepin'",
        employee_email: 'glenn@wilco.com',
        employee_id: '12345',
        employee_name: 'Glenn Kotche',
        employee_personal_email: 'glenn@gmail.com',
        employee_phone: '1(773)009-4526',
        employee_address: '123 North St, Berkeley, CA 94707',
      )
      form.submit!
    end

    assert_email RequestMailer.deliveries.last,
      subject: 'UC Berkeley Borrowing Card Requested',
      to: ['jeff@wilco.com']
  end
end
