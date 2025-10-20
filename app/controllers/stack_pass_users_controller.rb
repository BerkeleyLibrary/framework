# Manipulate stack pass / reference card admins.
class StackPassUsersController < ApplicationController
  before_action :auth_as_admin!
  before_action :set_user, only: %i[update destroy]

  self.support_email = 'privdesk-library@berkeley.edu'

  def index
    @users = Role.stackpass_admin.framework_users.order(:name)
  end

  def new
    @user = FrameworkUsers.new
  end

  def create
    # First check if the user exists in framework user - or create the user
    @user = FrameworkUsers.find_or_create_by(lcasid: user_params[:lcasid]) do |new_user|
      new_user.name = user_params[:name]
      new_user.role = 'Admin'
    end

    unless @user.persisted?
      render :new, status: :unprocessable_entity
      return
    end

    Assignment.create!(framework_users: @user, role: Role.stackpass_admin)
    redirect_to stack_pass_users_path, flash: { success: "Added #{@user.name} as an administrator" }
  end

  def destroy
    user_assignment = Assignment.where(framework_users: @user, role: Role.stackpass_admin).first
    user_assignment.destroy
    redirect_to stack_pass_users_path, flash: { success: "Removed #{@user.name} from administrator list" }
  end

  private

  # Ensure the current user is authenticated and an admin.
  def auth_as_admin!
    authenticate!
    @user_is_admin = current_user.role?(Role.stackpass_admin)
    redirect_to stack_pass_forms_path unless @user_is_admin
  end

  def set_user
    @user = FrameworkUsers.find_by(lcasid: params[:id])
  end

  def user_params
    params.require(:framework_users).permit(:lcasid, :name)
  end
end
