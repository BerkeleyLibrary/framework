require 'time'
# Start here tomorrow.... need to setup separate controllers (I THINK) for
# the two different sub models (stack_pass and reference_card)

class StackRequestsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :render_404

  def forbidden; end

  def index
    # redirect_with_params(action: :new)
    user_role = FrameworkUsers.role?(current_user.uid, 'stackpass_admin')
    @user_role = if user_role.blank?
                   nil
                 else
                   user_role
                 end
  end

end
