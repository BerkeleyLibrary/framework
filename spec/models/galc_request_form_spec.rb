require 'rails_helper'

describe GalcRequestForm do
  it 'limits authorization by by patron type' do
    tests = {
      Alma::Type::FACULTY => true,
      Alma::Type::GRAD_STUDENT => true,
      Alma::Type::LIBRARY_STAFF => true,
      Alma::Type::MANAGER => true,
      Alma::Type::STAFF => true,
      Alma::Type::UNDERGRAD => true,
      Alma::Type::UNDERGRAD_SLE => true,
      Alma::Type::POST_DOC => false
    }

    aggregate_failures 'patron types' do
      tests.each do |patron_type, authorized|
        patron = Alma::User.new
        patron.type = patron_type
        form = GalcRequestForm.new(patron:)
        if authorized
          expect { form.authorize! }.not_to raise_error
        else
          expect { form.authorize! }.to raise_error(Error::ForbiddenError)
        end
      end
    end
  end

  describe :support_email do
    it 'has a default value' do
      patron = Alma::User.new
      patron.type = Alma::Type::LIBRARY_STAFF
      form = GalcRequestForm.new(patron:)
      expect(form.support_email).to eq('eref@library.berkeley.edu')
    end
  end

  describe :patron_email do
    it 'defaults to the email from the patron record' do
      patron = Alma::User.new
      patron.type = Alma::Type::LIBRARY_STAFF
      patron.email = 'pince@library.berkeley.edu'
      form = GalcRequestForm.new(patron:)
      expect(form.patron_email).to eq('pince@library.berkeley.edu')
    end
  end

  describe :submit! do
    it 'submits the form' do
      patron = Alma::User.new
      patron.type = Alma::Type::LIBRARY_STAFF
      patron.name = 'Irma Pince'
      patron.email = 'pince@library.berkeley.edu'
      patron.id = 123_456

      form = GalcRequestForm.new(
        patron:,
        borrow_check: 'checked',
        fine_check: 'checked'
      )
      expect { form.submit! }.to have_enqueued_job(GalcRequestJob).with(patron.id)
    end
  end
end
