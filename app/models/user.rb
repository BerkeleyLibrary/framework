class User
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks
  extend Devise::Models

  devise :omniauthable, :omniauth_providers => [:calnet]

  attr_accessor :uid, :display_name, :employee_id

  def patron
    @patron ||= Patron.find(employee_id)
  end
end
