class User < ApplicationRecord 

devise :omniauthable, :omniauth_providers => [:altmedia] 


#def self.from_altmedia!(auth)
#	where(altmedia_uid: auth.uid).first_or_create do |user|
#      user.email = auth.info.email 
#      user.save!
#  end
#end
#
#def self.random_email
#	"#{SecureRandom.hex[0,16]}@noemail.com"
#end
#
#
#def to_s
#    email
#end


end
