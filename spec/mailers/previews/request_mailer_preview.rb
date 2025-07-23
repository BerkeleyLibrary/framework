class RequestMailerPreview < ActionMailer::Preview
  def security_incident_email
    incident = SecurityIncidentReportForm.new
    incident.incident_location = 'Camponille Tower'
    incident.incident_date = '12-31-2024'
    incident.incident_time = '00:16'
    incident.reporter_name = 'Donald McFly'
    incident.email = 'McFly@gmail.com'
    incident.unit = 'LIT'
    incident.phone = '222-222-2222'
    incident.incident_description = 'A drunken student climbed the campanile and stole one of the peregrine falcons'
    incident.theft_personal = 'checked'
    incident.theft_library = 'checked'
    incident.vandalism = 'checked'
    incident.assault = 'checked'
    incident.criminal_other = 'checked'
    incident.rules_violation = 'checked'
    incident.irate_abusive = 'checked'
    incident.physical_altercation = 'checked'
    incident.disruptive_other = 'checked'
    incident.power_outage = 'checked'
    incident.flooding = 'checked'
    incident.fire = 'checked'
    incident.elevator = 'checked'
    incident.facility_other = 'checked'
    incident.library_employee = 'checked'
    incident.student_patron = 'checked'
    incident.campus_employee = 'checked'
    incident.visitor = 'checked'
    incident.injury_other = 'checked'
    # rubocop:disable Layout/LineLength
    incident.injury_description = 'Broken arm from falling and numerous lacerations to face from being pecked at by falcon. Wrapped up arm in printing paper and covered lacerations with glue to stop bleeding. I believe the ambulance brought them to Kaiser after reprimanding staff for horrible attempt rendering assistance'
    # rubocop:enable Layout/LineLength
    incident.subject_affiliation = 'Student'
    incident.race = 'White'
    incident.sex = 'Male'
    incident.build = 'Medium'
    incident.height = "5'9\""
    incident.weight = '185'
    incident.hair = 'brown'
    incident.eyes = 'brown'
    incident.clothing = 'Red sweat jacket, jeans, blue hat'
    incident.subject_affiliation_1 = 'Student'
    incident.race_1 = 'Black'
    incident.sex_1 = 'Femail'
    incident.build_1 = 'Medium'
    incident.height_1 = "5'3\""
    incident.weight_1 = '150'
    incident.hair_1 = 'black'
    incident.eyes_1 = 'brown'
    incident.clothing_1 = 'Blue coat'
    incident.subject_affiliation_2 = 'Campus Employee'
    incident.race_2 = 'White'
    incident.sex_2 = 'Male'
    incident.build_2 = 'Small'
    incident.height_2 = "5'2\""
    incident.weight_2 = '130'
    incident.hair_2 = 'brown'
    incident.eyes_2 = 'brown'
    incident.clothing_2 = 'Big coat, green sneakers, tattoo on face that says Dukakis/Bentsen 88!'
    incident.property_description = 'Peregrine Falcon'
    incident.police_notified = 'yes'
    incident.police_report_number = 'B919294923'
    incident.officer_name_badge = 'Officer Henry Camden, B3040305'
    incident.fire_department = 'checked'
    incident.sup_email = 'jdoe@gmail.com'

    RequestMailer.security_incident_email(incident)
  end

  def doemoff_patron_email
    patron_email = DoemoffPatronEmailForm.new
    patron_email.patron_email = 'test@gmail.com'
    # rubocop:disable Style/StringLiterals
    patron_email.patron_message = "We found the book you were looking for. Under the lamp near the entrance " \
                                  "you will find a piece of paper with a riddle which (if properly solved) will " \
                                  "direct you to the next riddle.\nSolve all the riddles correctly " \
                                  "and it will lead you to your book"
    # rubocop:enable Style/StringLiterals
    patron_email.recipient_email = 'maincirc-library@berkeley.edu'
    RequestMailer.doemoff_patron_email(patron_email)
  end

  def departmental_card_email
    departmental_card = DepartmentalCardForm.new
    departmental_card.name = 'Andy Dufresne'
    departmental_card.email = 'andy_dufresne@shawshank.org'
    departmental_card.phone = '510-555-5555'
    departmental_card.address = '124 North Main Street, Portland, ME 04101'
    departmental_card.supervisor_name = 'Brooks Hatlen'
    departmental_card.supervisor_email = 'bhatlen@shawshank.org'
    departmental_card.barcode = 'K81433-SHNK'
    departmental_card.reason = 'Adding books to the library.'

    RequestMailer.departmental_card_form_email(departmental_card)
  end
end
