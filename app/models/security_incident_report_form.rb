class SecurityIncidentReportForm < Form
  ATTRIBUTES = %i[
    incident_location
    incident_date
    incident_time
    reporter_name
    email
    unit
    phone
    incident_description
    theft_personal
    theft_library
    vandalism
    assault
    criminal_other
    rules_violation
    irate_abusive
    physical_altercation
    disruptive_other
    power_outage
    flooding
    elevator
    fire
    facility_other
    library_employee
    student_patron
    campus_employee
    visitor
    injury_other
    injury_description
    subject_affiliation
    race
    sex
    build
    height
    weight
    hair
    eyes
    clothing
    subject_affiliation_1
    race_1
    sex_1
    build_1
    height_1
    weight_1
    hair_1
    eyes_1
    clothing_1
    subject_affiliation_2
    race_2
    sex_2
    build_2
    height_2
    weight_2
    hair_2
    eyes_2
    clothing_2
    property_description
    police_report_number
    officer_name_badge
    fire_department
    sup_email
    police_notified
  ].freeze

  SecurityIncident = Struct.new(*ATTRIBUTES, keyword_init: true)

  attr_accessor(*ATTRIBUTES)

  validates :email, :sup_email,
            email: true,
            presence: true

  validates :incident_location, :incident_date, :incident_time, :reporter_name, :unit, :phone,
            :incident_description, presence: true

  def to_h
    ATTRIBUTES.index_with { |attr| public_send(attr) }
  end

  def submit!
    raise ActiveModel::ValidationError, self unless valid?

    RequestMailer.security_incident_email(to_h).deliver_later
  end
end
