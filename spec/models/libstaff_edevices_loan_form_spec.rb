require 'rails_helper'

describe LibstaffEdevicesLoanForm do
  describe :submit do
    attr_reader :patron
    attr_reader :form

    before(:each) do
      @patron = Alma::User.new
      @patron.id = 12_345
      @patron.email = 'jdoe@berkeley.test'
      @patron.type = Alma::Type::LIBRARY_STAFF

      @form = LibstaffEdevicesLoanForm.new(
        patron: patron,
        display_name: 'Jane Doe',
        borrow_check: 'checked',
        edevices_check: 'checked',
        fines_check: 'checked',
        lending_check: 'checked'
      )
    end

    it 'submits a job' do
      expect { form.submit! }.to have_enqueued_job(LibstaffEdevicesLoanJob).with(patron.id)
    end

    describe :patron_type do
      it 'requires a patron type' do
        patron.type = nil
        expect { form.submit! }.to raise_error(Error::ForbiddenError)
      end

      it 'requires the patron type to be LIBRARY_STAFF' do
        invalid_types = Alma::Type.all.reject { |t| t == Alma::Type::LIBRARY_STAFF }
        aggregate_failures 'patron type validation' do
          invalid_types.each do |t|
            patron.type = t
            expect { form.submit! }.to raise_error(Error::ForbiddenError)
          end
        end
      end
    end

    describe 'validations' do
      %i[borrow_check lending_check fines_check edevices_check].each do |field|
        it "requires an explicit opt-in for #{field}" do
          form.send("#{field}=", nil)
          expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
        end
      end

      it 'requires a display name' do
        form.display_name = nil
        expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
      end

      it 'requries an email address' do
        patron.email = nil
        expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
      end

      it 'requires a valid-ish email address' do
        patron.email = '<jane at berkeley>'
        expect { form.submit! }.to raise_error(ActiveModel::ValidationError)
      end
    end

  end
end
