require 'rails_helper'

describe LocationRequestsAlertHelper, type: :helper do
  let(:configured_alert) { nil }

  before do
    allow(Rails.configuration).to receive(:location_requests_alert).and_return(configured_alert)
  end

  describe '#location_requests_alert' do
    subject(:location_requests_alert) { helper.location_requests_alert }

    context 'when the alert is not configured' do
      it { is_expected.to be_nil }
    end

    context 'when the alert is blank' do
      let(:configured_alert) { ' ' }

      it { is_expected.to be_nil }
    end

    context 'when the alert is configured' do
      let(:configured_alert) { 'OCLC requests are currently rate limited.' }

      it { is_expected.to eq(configured_alert) }
    end
  end

  describe '#display_location_requests_alert' do
    subject(:output) { helper.display_location_requests_alert }

    context 'when the alert is not configured' do
      it { is_expected.to be_nil }
    end

    context 'when the alert is configured' do
      let(:configured_alert) { 'OCLC requests are currently rate limited.' }

      it 'renders the configured message as a warning alert' do
        render html: output

        assert_dom 'div.alert.alert-warning[role=?]', 'alert', text: configured_alert, count: 1
      end
    end
  end
end
