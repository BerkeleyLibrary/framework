require 'rails_helper'

describe ScanRequestForm do

  attr_reader :patron
  attr_reader :form

  describe 'allowed' do
    allowed_patron_types = [
      Alma::Type::FACULTY,
      Alma::Type::STAFF,
      Alma::Type::LIBRARY_STAFF,
      Alma::Type::MANAGER,
      Alma::Type::VISITING_SCHOLAR,
      Alma::Type::UCB_ACAD_AFFILIATE
    ]

    allowed_patron_types.each do |type|
      describe Alma::Type.name_of(type) do
        before do
          @patron = Alma::User.new
          @patron.email = 'winner@civil-war.com'
          @patron.id = '1865'
          @patron.name = 'Ulysses S. Grant'
          @patron.type = type

          @form = ScanRequestForm.new(
            opt_in: 'true',
            patron:,
            patron_name: 'Ulysses S. Grant'
          )
        end

        it 'is valid' do
          expect(form.valid?).to eq(true)
          expect(form.patron_id).to eq('1865')
          expect(ScanRequestForm.patron_eligible?(form.patron)).to eq(true)
        end

        it 'populates the patron email' do
          expect(form.patron_email).to eq('winner@civil-war.com')
        end

        it 'disallows blocked patrons' do
          form.patron.blocks = 'something'
          expect { form.submit! }.to raise_error(Error::ForbiddenError)
        end

        it 'checks opt-in flag' do
          form.opt_in = 'maybe'
          expect(form.valid?).to eq(false)
        end

        it 'queues an opt-in job' do
          form.opt_in = 'true'
          expect { form.submit! }.to have_enqueued_job(ScanRequestOptInJob).with(patron.id)
        end

        it 'queues an opt-out job' do
          form.opt_in = 'false'
          expect { form.submit! }.to have_enqueued_job(ScanRequestOptOutJob).with(patron.id)
        end
      end
    end
  end

  describe 'forbidden' do
    forbidden_patron_types = [
      Alma::Type::UNDERGRAD,
      Alma::Type::UNDERGRAD_SLE,
      Alma::Type::GRAD_STUDENT,
      Alma::Type::POST_DOC
    ]

    forbidden_patron_types.each do |type|
      describe Alma::Type.name_of(type) do
        before do
          @patron = Alma::User.new
          @patron.email = 'winner@civil-war.com'
          @patron.id = '1865'
          @patron.type = type

          @form = ScanRequestForm.new(
            opt_in: 'true',
            patron:,
            patron_name: 'Ulysses S. Grant'
          )
        end

        it 'is invalid' do
          expect { form.valid? }.to raise_error(Error::ForbiddenError)
          expect(ScanRequestForm.patron_eligible?(form.patron)).to eq(false)
        end
      end
    end
  end

  describe :model_name do
    it 'has a human name' do
      expect(ScanRequestForm.model_name.human).to eq('Faculty Alt-Media Scanning')
    end
  end
end
