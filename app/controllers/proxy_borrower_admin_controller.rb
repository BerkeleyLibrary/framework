require 'time'

# class ProxyBorrowerAdminController < ApplicationController
class ProxyBorrowerAdminController < AuthenticatedFormController
  helper_method :sort_column, :sort_direction
  before_action :admin?

  def admin
    # wisks us over to the admin page...yay, we're going to the admin page!
  end

  def admin_view
    # Hey, let's look at all these glorious requests!!!
    # @requests = ProxyBorrowerRequests.all.order(sort_column + ' ' + sort_direction)
    @requests = ProxyBorrowerRequests.where('date_term > ?', Date.today).order(sort_column + ' ' + sort_direction)
  end

  def admin_export
    # Let's give this admin all of the records in a file
    # @requests = ProxyBorrowerRequests.all.order(created_at: :desc)
    @requests = ProxyBorrowerRequests.where('date_term > ?', Date.today).order(created_at: :desc)

    respond_to do |format|
      format.html { redirect_to forms_proxy_borrower_admin_path }
      format.csv { send_data @requests.to_csv, filename: "ProxyRequests-#{Date.today}.csv" }
    end
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def admin_search
    # Search page...yay
    search_parameter = params[:search_term] || params[:param]
    return unless search_parameter.present?

    # Need to send the search term back with the results so if
    # the user wants to sort differently, we can send back the
    # search term (comes back in the 'param' field)
    @search_term_param = search_parameter

    begin
      # Since we may be searching date fields let's
      # first check if our parameter is a valid date:
      search_date = Date.strptime(search_parameter, '%m/%d/%Y')

      # create a time range for the entire day:
      time_range = (search_date.beginning_of_day..search_date.end_of_day)

      # search both created_at and date_term fields:
      @requests = ProxyBorrowerRequests.where(created_at: time_range)
        .or(ProxyBorrowerRequests.where(date_term: time_range))
        .order(sort_column + ' ' + sort_direction)
    rescue ArgumentError
      # Not really an ArgumentError - but rubocop wants me to specify
      # what I'm rescuing here.
      # ANYWAY...If our search param is not a date just check all the 'name' fields:
      # @requests = ProxyBorrowerRequests.where('faculty_name ILIKE :search
      #     OR student_name ILIKE :search OR dsp_rep ILIKE :search
      #     OR research_last ILIKE :search OR research_first ILIKE :search',
      #                                         search: "%#{search_parameter}%").order(sort_column + ' ' + sort_direction)
      unfiltered_requests = ProxyBorrowerRequests.where('faculty_name ILIKE :search
          OR student_name ILIKE :search OR dsp_rep ILIKE :search
          OR research_last ILIKE :search OR research_first ILIKE :search',
                                                        search: "%#{search_parameter}%").order(sort_column + ' ' + sort_direction)

      # I could not figure out how to add the date term condition to the above query
      # so filtering the results into an array to be passed back to the view:
      @requests = []
      unfiltered_requests.each do |r|
        @requests.push(r) if r.date_term > Date.today
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def admin_users
    # I'll need to grab all of the Proxy Borrower User's (admins...not requesters)
    @users = ProxyBorrowerUsers.all.order(:name)
  end

  def add_admin
    admin = ProxyBorrowerUsers.new
    admin.name = params['name'] || nil
    admin.lcasid = params['lcasid'] || nil
    # We've removed the 'Sub-Admin' role so just hardcoding role to 'Admin' now:
    admin.role = 'Admin'
    admin.save
    flash[:success] = "Added #{admin.name} as an administrator"
    redirect_to forms_proxy_borrower_admin_users_path
  end

  def destroy_admin
    admin = ProxyBorrowerUsers.find(params[:id])
    admin_name = admin.name
    admin.destroy
    flash[:success] = "Removed #{admin_name} from administrator list"
    redirect_to forms_proxy_borrower_admin_users_path
  end

  private

  def init_form!; end

  # You shall not pass....unless you're an admin
  def admin?
    user_role = ProxyBorrowerUsers.proxy_user_role(current_user.uid)

    if user_role.blank?
      # In this case we'll want to re-route the user to the main (index) page
      redirect_to proxy_borrower_forms_path
    else
      # Might not be necessary to pass the role
      # I don't think there's much of a difference now between admin/subadmin
      @user_role = user_role
    end
  end

  def sort_column
    # only allow column names as sorting param
    ProxyBorrowerRequests.column_names.include?(params[:sort]) ? params[:sort] : 'created_at'
  end

  def sort_direction
    # only alow asc||desc for direction param
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end
end
