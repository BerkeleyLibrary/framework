require 'rails_helper'

describe DoemoffPatronEmailForm do

  attr_reader :form

  # verify params are valid
  describe 'is valid' do
    describe 'form' do
      before do
        @form = DoemoffPatronEmailForm.new
        @form.patron_email = 'duner@berkeley.edu'
        @form.patron_message = 'test message'
        @form.sender = 'libtest@berkeley.edu'
        @form.recipient_email = 'main-circ@berkeley.edu'
      end

      it 'is valid' do
        expect(@form.valid?).to eq(true)
      end

      it 'sends an email' do
        expect { @form.submit! }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
    end
  end

  # Missing a required parameter should cause it to fail
  describe 'is not valid' do
    describe 'form' do
      before do
        @form = DoemoffPatronEmailForm.new
        @form.patron_email = 'duner@berkeley.edu'
        @form.patron_message = 'test message'
        @form.sender = 'libtest@berkeley.edu'
      end

      it 'is not valid' do
        expect(@form.valid?).to eq(false)
      end

    end
  end

  # malformed email should cause it to fail
  describe 'malformed email fails' do
    describe 'form' do
      before do
        @form = DoemoffPatronEmailForm.new
        @form.patron_email = 'duey.edu'
        @form.patron_message = 'test message'
        @form.sender = 'libtest@berkeley.edu'
        @form.recipient_email = 'main-circ@berkeley.edu'
      end

      it 'is not valid' do
        expect(@form.valid?).to eq(false)
      end

    end
  end
end
