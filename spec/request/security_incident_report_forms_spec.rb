require 'rails_helper'
require 'calnet_helper'
RSpec.describe SecurityIncidentReportFormsController, type: :request do
  context 'specs for unauthorized user' do
    before do
      logout!
    end

    context 'index' do
      it 'GET requires login' do
        get security_incident_report_forms_path
        expect(response).to have_http_status :unauthorized
      end
    end
  end

  context 'specs for logged in user' do
    before do
      mock_login(CalnetHelper::STACK_REQUEST_ADMIN_UID)
      @required_params = {
        incident_location: 'Camponille Tower',
        incident_date: '2024-05-03',
        incident_time: '22:16',
        reporter_name: 'Donald McFly',
        email: 'McFly@gmail.com',
        unit: 'LIT',
        phone: '510-222-2222',
        incident_description: 'A drunken student climbed the campanile and stole one of the peregrine falcons',
        sup_email: 'jdoe@gmail.com'
      }

      @unknown_param = @required_params.merge(should_fail: 'this param does not exist')

      @section_type = @required_params.merge(police_notified: 'Police notified')
    end

    it 'rejects a submission with missing fields' do
      post('/forms/security-incident-report', params: {
             security_incident_report_form: {}
           })
      expect(response).to redirect_to(new_security_incident_report_form_path)
    end

    it 'accepts a submission with required params' do
      params = { security_incident_report_form: @required_params }
      post('/forms/security-incident-report', params:)
      expect(response).to have_http_status :ok
    end

    it 'fails if an invalid param is sent' do
      params = { security_incident_report_form: @unknown_param }
      expect { post('/forms/security-incident-report', params:) }.to raise_error ActiveModel::UnknownAttributeError
    end

    it 'Brings up the success page when a submissions is properly submitted' do
      params = { security_incident_report_form: @section_type }
      post('/forms/security-incident-report', params:)
      expect(response.body).to match(/The Incident Report Form has been successfully submitted./)
    end

  end
end
