class User
  include ActiveModel::Model

  attr_accessor :uid, :display_name, :employee_id

  def authenticated?
    not uid.nil?
  end

  def patron
    @patron ||= Patron.find(employee_id)
  end
end
