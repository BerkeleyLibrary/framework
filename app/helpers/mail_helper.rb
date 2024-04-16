module MailHelper

  # Used for security incident report form email which has a gazillion fields.

  # Check if any checkboxes are checked for a section.
  def section_has_value_checked?(security_form, section)
    sections(section).each do |value|
      return true if security_form.send(value.keys[0]) == 'checked'
    end
    false
  end

  # map checkbox groupings along with formatted display. Should probably move this to a config at some point.
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  def sections(section_type)
    case section_type
    when 'criminal'
      [{ theft_personal: 'Theft-personal items' }, { theft_library: 'Theft-library property' }, { vandalism: 'Vandalism-damaged property' },
       { assault: 'Assualt' }, { criminal_other: 'Other' }]
    when 'disruptive'
      [{ rules_violation: 'Rules violation' }, { irate_abusive: 'Irate, abusive, disorderly conduct' },
       { physical_altercation: 'Physical Altercation' }, { disruptive_other: 'Disruptive behavior' }]
    when 'facility'
      [{ power_outage: 'Power outage' }, { flooding: 'Flooding' }, { elevator: 'Elevator' }, { fire: 'Fire' }, { facility_other: 'Other' }]
    when 'injury'
      [{ library_employee: 'Library employee' }, { student_patron: 'Student (patron)' }, { campus_employee: 'Campus employee' },
       { visitor: 'Visitor' }, { injury_other: 'Other' }]
    when 'police_notified'
      [{ police_notified: 'Police notified' }]
    when 'subject_affiliation'
      [{ subject_affiliation: 'Subject affiliation' }, { race: 'Race' }, { sex: 'Sex' }, { build: 'Build' }, { height: 'Height' },
       { weight: 'Weight' }, { hair: 'Hair' }, { eyes: 'Eyes' }, { clothing: 'Clothing' }]
    when 'subject_affiliation_1'
      [{ subject_affiliation_1: 'Subject affiliation' }, { race_1: 'Race' }, { sex_1: 'Sex' }, { build_1: 'Build' }, { height_1: 'Height' },
       { weight_1: 'Weight' }, { hair_1: 'Hair' }, { eyes_1: 'Eyes' }, { clothing_1: 'Clothing' }]
    when 'subject_affiliation_2'
      [{ subject_affiliation_2: 'Subject affiliation' }, { race_2: 'Race' }, { sex_2: 'Sex' }, { build_2: 'Build' }, { height_2: 'Height' },
       { weight_2: 'Weight' }, { hair_2: 'Hair' }, { eyes_2: 'Eyes' }, { clothing_2: 'Clothing' }]
    else
      []
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength

  # We only want to display form values if there's something actually selected.
  def display_type_of_incident(security_incident, section_type)
    html = ''
    sections(section_type).each do |value|
      html << "<li>#{value.values[0]}</li>" if security_incident.send(value.keys[0]) == 'checked'
    end
    html
  end

  def display_subject_affiliation(security_incident, section_type)
    html = ''
    sections(section_type).each do |value|
      html << "<div>#{value.values[0]}: #{security_incident.send(value.keys[0])}</div>" unless security_incident.send(value.keys[0]).nil?
    end
    html
  end

  # End of security incident report section
end
