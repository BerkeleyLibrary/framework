require 'open-uri'

module ScanHelper
  class OskiCatError < StandardError
    def initialize(msg="Couldn't connect to OskiCat. Is the server allowed to connect?")
      super
    end
  end

  def patron_info_url(user_id)
    URI::join(Rails.application.config.patron_url, "#{user_id}/dump")
  end

  def get_patron_info(user_id)
    endpoint = patron_info_url(user_id)

    logger.debug("Getting Patron info: #{endpoint}")

    begin
      return open(endpoint, {
        # TODO: Instead of waving SSL, we can add the target server's root
        # certificate to our host's trusted certificates.
        ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
      }).read
    rescue StandardError
      raise OskiCatError
    end
  end

  def verify_faculty_standing(empid, displayname)
    @empid = empid.gsub(/\D/, '')
    @displayName = displayname

    contents = get_patron_info(@empid)

    #find out if they are faculty.
    ptype_re = /P\sTYPE\[p47\]\=(\d.*?)/i
    if ptype = contents.match(ptype_re)
      ptype_result = ptype.captures[0]
    end

    #find out if they are in good standing
    standing_re = /MBLOCK\[p56\]\=(.*?)\<br/i
    if standing = contents.match(standing_re)
      standing_result = standing.captures[0]
    end

    if ptype_result.eql?("6") &&  standing_result.eql?("-")
       #patron is factulty in good standing get email and let them request scanning request privileges
       faculty_email = get_email(contents)

       #passing verified to just ensure they didn't get to the form page some other way without validating.
       render("scanrequest",verified: 1,faculty_email: faculty_email,emp_id: @empid,display_name: @displayName)
    elsif not ptype_result.eql?("6")
      #patron is not in good standing return proper message
      #to do route them to a page letting them know why they can't gain scanning request privileges.
      render("notfaculty")
    elsif not standing_result.eql?("-")
      render("blocked")
    end
  end

  #get the email address
  def get_email(contents)
    email_re = /EMAIL\sADDR\[pz\]\=(\w.*?)\<br/i
    if email = contents.match(email_re)
      email_result = email.captures[0]
      return email_result
    end

    #to do. Add handling if email wasn't found
  end

  #def get_ip
  #	ip_address = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }.ip_address
  #end
end
