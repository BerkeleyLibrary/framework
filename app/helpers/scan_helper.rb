module ScanHelper
require 'open-uri'
require 'socket'
require 'net/ssh'



def verify_faculty_standing(empid)

  @empid = empid
  info = open("https://dev-oskicatp.berkeley.edu:54620/PATRONAPI/#{empid}/dump",{ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})
  contents = info.read

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
     render("scanrequest",verified: 1,faculty_email: faculty_email,emp_id: @empid)
     
  elsif not ptype_result.eql?("6")
    #patron is not in good standing return proper message
    #to do route them to a page letting them know why they can't gain scanning request privileges.
    render("notfaculty") 
  elsif not standing_result.eql?("-")
    render("blocked") 
  else
    return standing_result
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
