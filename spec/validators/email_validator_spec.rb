require 'spec_helper'
require 'active_model'
require_relative '../../app/validators/email_validator'

describe EmailValidator do
  subject(:email_model) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :email

      validates :email, email: true
    end
  end

  it 'accepts valid emails' do
    model = email_model.new(email: 'student@berkeley.edu')
    model.validate
    expect(model.errors).to be_empty
  end

  it 'rejects invalid emails' do
    model = email_model.new(email: 'student')
    model.validate
    expect(model.errors).to include(:email)
  end
end
