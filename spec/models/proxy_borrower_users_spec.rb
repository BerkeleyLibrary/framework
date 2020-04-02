require 'rails_helper'

describe ProxyBorrowerUsers do
  it 'validates a Proxy Borrower User object' do
    tests = [
      {
        valid: false,
        attributes: {},
        errors: {
          lcasid: ["can't be blank"],
          name: ["can't be blank"],
          role: ["can't be blank"]
        }
      },
      {
        valid: true,
        attributes: {
          lcasid: '1234567',
          name: 'Darth Vader',
          role: 'Admin'
        },
        errors: {
          dsp_rep_name: []
        }
      }
    ]
    tests.each do |attributes:, errors:, valid:|
      form = ProxyBorrowerUsers.new(attributes)
      expect(form.valid?).to eq(valid)
      next if valid

      errors.each do |attr_name, attr_errs|
        expect(form.errors[attr_name]).to eq(attr_errs)
      end
    end
  end
end
