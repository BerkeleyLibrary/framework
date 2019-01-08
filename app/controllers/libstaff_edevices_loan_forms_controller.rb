class LibstaffEdevicesLoanFormsController < ApplicationController
  #First redirect the user to the CalNet login page
  before_action :authenticate!
  #Before loading the form, check that the user is library staff. If not, display a you cannot enter message
  before_action :init_form!

  def index
    #Redirect the user from /forms/library-staff-devices to /forms/library-staff-devices/new
    redirect_with_params(action: :new)
  end

  def new
    #Check to confirm the user is library staff and a patron in good standing, i.e. no blocks in account
    if not @form.allowed?
      render :forbidden, status: :forbidden
    elsif @form.blocked?
      render :blocked, status: :forbidden
    else
      render :new
    end
  end

  def create
    @form.process(params)
    #After user submits form, if all boxes were checked, display a confirmation message and send an email
    redirect_to action: :show, id: :all_check
  rescue ActiveModel::ValidationError
    flash[:danger] ||= []
    @form.errors.full_messages.each {|msg| flash[:danger] << msg}
    redirect_with_params(action: :new)
  end

  def show
    if %w(blocked forbidden all_check).include?(params[:id])
      render params[:id]
    else
      redirect_with_params(action: :new)
    end
  end


  private

  def init_form!
    d = DateTime.now
    today_date = d.strftime("%m/%d/%Y")
    @form = LibstaffEdevicesLoanForm.new(
      patron: current_user.employee_patron_record,
      patron_name: current_user.display_name,
      today_date: today_date,
    )
    #{"patron":{"id":"013191304","affiliation":"0","blocks":null,"email":"ethomas@berkeley.edu","name":"THOMAS,ELISSA","type":"6"},"patron_name":"Elissa Thomas"}
    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  def form_params
    #Make sure only specified attributes are allowed as params
    params.require(:libstaff_edevices_loan_form).permit(:borrow_check, :lending_check, :fines_check, :edevices_check, :full_name, :staff_id_number, :today_date, :staff_email)
  rescue ActionController::ParameterMissing
    {}
  end

end