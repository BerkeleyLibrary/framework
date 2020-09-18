require 'time'

class StackPassAdminController < AuthenticatedFormController
  helper_method :sort_column, :sort_direction
  before_action :admin?

  def admin; end

  def requests
    @requests = StackPassForm.all.order(sort_column + ' ' + sort_direction)
  end

  def users
    @users = FrameworkUsers.users_with_role('stackpass_admin')
    @users.sort! { |a, b| a.name <=> b.name }
  end

  def add_user
    # First check if the user exists in framework user - or create the user
    framework_user = FrameworkUsers.check_db(params['lcasid']) || FrameworkUsers.create(name: params['name'], lcasid: params['lcasid'], role: 'Admin')

    # Now that we have the user, create the assignment:
    Assignment.create(framework_users_id: framework_user.id, role_id: 2)

    # And redirect back to the admin users page:
    flash[:success] = "Added #{framework_user.name} as an administrator"
    redirect_to forms_stack_pass_admin_users_path
  end

  def destroy_user
    # First grab the user (so we can grab the name!)
    admin = FrameworkUsers.find(params[:id])
    admin_name = admin.name

    # Now lets find the assignment
    # role id 2 == stackpass_admin
    user_assignment = Assignment.where(framework_users_id: admin.id, role_id: 2).first
    user_assignment.destroy
    flash[:success] = "Removed #{admin_name} from administrator list"
    redirect_to forms_stack_pass_admin_users_path
  end

  private

  def init_form!; end

  # You shall not pass....unless you're an admin
  def admin?
    if FrameworkUsers.role?(current_user.uid, 'stackpass_admin')
      @user_role = 'Admin'
    else
      redirect_to stack_pass_forms_path
    end
  end

  def sort_column
    # only allow column names as sorting param
    StackPassForm.column_names.include?(params[:sort]) ? params[:sort] : 'created_at'
  end

  def sort_direction
    # only allow asc||desc for direction param
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

end
