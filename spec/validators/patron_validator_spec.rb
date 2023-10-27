require 'rails_helper'
require 'spec_helper'

describe PatronValidator do
  it 'validates that the patron is actually an Alma::User' do
    model = create_patron_model(Alma::User.new)
    model.validate!

    model = create_patron_model(nil)
    expect { model.validate! }.to raise_error Error::PatronNotFoundError
  end

  it 'validates patron based on their notes' do
    patron = Alma::User.new
    patron.user_obj = { 'user_note' => [] }
    patron.add_note('This user never returns books on time')

    model = create_patron_model(patron, note: /never returns/)
    model.validate!

    model = create_patron_model(patron, note: /always returns/)
    expect { model.validate! }.to raise_error Error::PatronNotEligibleError
  end

  it 'validates patrons based on the configured type' do
    patron = Alma::User.new
    patron.type = 'SOME_TYPE'

    model = create_patron_model(patron, types: ['SOME_TYPE'])
    model.validate!

    model = create_patron_model(patron, types: ['SOME_OTHER_TYPE'])
    expect { model.validate! }.to raise_error Error::ForbiddenError
  end

  it 'invalidates patrons with blocks' do
    patron = Alma::User.new
    patron.blocks = false

    model = create_patron_model(patron)
    model.validate!

    patron.blocks = true
    model = create_patron_model(patron)
    expect { model.validate! }.to raise_error Error::PatronBlockedError
  end

  private

  def create_patron_model(patron, types: [], note: nil)
    Class.new do
      include ActiveModel::Model

      attr_accessor :patron

      validates :patron, patron: { types:, note: }
    end.new(patron:)
  end
end
