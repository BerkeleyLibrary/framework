class DoemoffStudyRoomUseFormsController < ApplicationController

  before_action :authenticate!
  before_action :init_form!

  def index
    redirect_to action: :new
  end

  def create
    @form.submit!
    redirect_to action: :show, id: :all_checked
  rescue ActiveModel::ValidationError => e
    Rails.logger.error(e)

    flash[:danger] ||= []
    @form.errors.full_messages.each { |msg| flash[:danger] << msg }
    redirect_with_params(action: :new)
  end

  def show
    if %w[blocked forbidden all_checked].include?(params[:id])
      render params[:id]
    else
      redirect_to action: :new
    end
  end

  private

  def init_form!
    @form = DoemoffStudyRoomUseForm.new(
      display_name: current_user.display_name,
      patron: current_user.primary_patron_record
    )
    @form.authorize!
    @form.validate unless @form.assign_attributes(form_params).blank?
  end

  # Make sure only specified attributes are allowed as params
  def form_params
    params.require(:doemoff_study_room_use_form).permit(
      :borrow_check,
      :fines_check,
      :roomUse_check
    )
  rescue ActionController::ParameterMissing
    {}
  end
end
