require 'rails_helper'

describe SecurityIncidentReportForm do

  attr_reader :form

  # verify params are valid
  describe 'is valid' do
    describe 'form' do
      before do
        params = {
          incident_location: 'Doe Library',
          incident_date: '2024-04-15',
          incident_time: '18:30',
          reporter_name: 'John Doe',
          email: 'jdoe@gmail.com',
          unit: 'LIT',
          phone: '530-200-2222',
          incident_description: 'assault with injury',
          theft_personal: 'checked',
          theft_library: 'checked',
          vandalism: 'checked',
          assault: 'checked',
          criminal_other: 'checked',
          rules_violation: 'checked',
          irate_abusive: 'checked',
          physical_altercation: 'checked',
          disruptive_other: 'checked',
          power_outage: 'checked',
          flooding: 'checked',
          elevator: 'checked',
          fire: 'checked',
          facility_other: 'checked',
          library_employee: 'checked',
          student_patron: 'checked',
          campus_employee: 'checked',
          visitor: 'checked',
          injury_other: 'checked',
          injury_description: 'broken arm',
          subject_affiliation: 'student',
          race: 'white',
          sex: 'male',
          build: 'small',
          height: '5 ft. 6',
          weight: '120',
          hair: 'brown',
          eyes: 'blue',
          clothing: 'red sweater',
          subject_affiliation_1: 'student',
          race_1: 'asian',
          sex_1: 'male',
          build_1: 'medium',
          height_1: '5 ft. 10',
          weight_1: '180',
          hair_1: 'black',
          eyes_1: 'brown',
          clothing_1: 'brown sweater',
          subject_affiliation_2: 'student',
          race_2: 'black',
          sex_2: 'female',
          build_2: 'slight',
          height_2: '5 ft. 2',
          weight_2: '110',
          hair_2: 'black',
          eyes_2: 'brown',
          clothing_2: 'red dress',
          property_description: 'damaged iphone',
          police_notified: 'yes',
          police_report_number: 'B818309403',
          officer_name_badge: 'B87901',
          fire_department: 'yes',
          sup_email: 'duner@berkeley.edu'
        }
        @form = SecurityIncidentReportForm.new(params)
      end

      it 'is valid' do
        expect(@form.valid?).to eq(true)
      end

      it 'enqueues the security incident email' do
        form = SecurityIncidentReportForm.new(
          incident_location: 'Doe Library',
          incident_date: Date.current,
          incident_time: '14:30',
          reporter_name: 'Lucas Van Donnelay',
          email: 'lvandonnelay@berkeley.edu',
          sup_email: 'sup@berkeley.edu',
          unit: 'LIT',
          phone: '510-555-1234',
          incident_description: 'Put book back on shelf in incorrect call number order'
        )

        expect { form.submit! }.to have_enqueued_job(ActionMailer::MailDeliveryJob)
      end
    end
  end

  # Missing a required parameter should cause it to fail
  describe 'is not valid' do
    describe 'form' do
      before do
        params = {
          incident_location: 'Doe Library',
          incident_date: '2024-04-15',
          incident_time: '1830',
          reporter_name: 'John Doe',
          email: 'jdoe@gmail.com',
          unit: 'LIT',
          phone: '530-200-2222'
        }
        @form = SecurityIncidentReportForm.new(params)
      end

      it 'is not valid' do
        expect(@form.valid?).to eq(false)
      end

    end
  end
end
