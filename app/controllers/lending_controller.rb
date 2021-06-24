# rubocop:disable Metrics/ClassLength
class LendingController < ApplicationController
  # ------------------------------------------------------------
  # Constants

  # TODO: Use Rails i18n
  MSG_NOT_CHECKED_OUT = 'This item is not checked out.'.freeze

  # ------------------------------------------------------------
  # Helpers

  helper_method :sort_column, :sort_direction, :lending_admin?, :manifest_url

  # ------------------------------------------------------------
  # Hooks

  before_action(:authenticate!)
  before_action(:require_lending_admin!, only: %i[index new create edit update destroy])
  before_action(:ensure_lending_item!, except: %i[index new create])

  # ------------------------------------------------------------
  # Controller actions

  # ------------------------------
  # UI actions

  def index
    @lending_items = LendingItem.order(sort_column + ' ' + sort_direction)
  end

  def new
    @lending_item = LendingItem.new
  end

  def edit; end # TODO: is this necessary?

  def show
    ensure_lending_item_loan!
    flash[:danger] = reason_unavailable unless lending_admin? || available?
  end

  def manifest
    require_active_loan! unless lending_admin?

    # TODO: cache this, or generate ERB, or something
    manifest = @lending_item.create_manifest(manifest_url)
    render(json: manifest)
  end

  # ------------------------------
  # Form handlers

  def create
    @lending_item = LendingItem.create(lending_item_params)
    render_with_errors(:new, @lending_item.errors, locals: { item: @lending_item }) && return unless @lending_item.persisted?

    flash[:success] = 'Item created.'
    redirect_to lending_show_url(directory: directory)
  end

  def update
    render_with_errors(:edit, errors) && return unless @lending_item.update(lending_item_params)

    flash[:success] = 'Item updated.'
    redirect_to lending_show_url(directory: directory)
  end

  def check_out
    @lending_item_loan = @lending_item.check_out_to(patron_identifier)
    render_with_errors(:show, @lending_item_loan.errors) && return unless @lending_item_loan.persisted?

    flash[:success] = 'Checkout successful.'
    redirect_to lending_show_url(directory: directory)
  end

  def return
    if active_loan
      active_loan.return!
      flash[:success] = 'Item returned.'
    else
      flash[:danger] = MSG_NOT_CHECKED_OUT
    end

    redirect_to lending_show_url(directory: directory)
  end

  def destroy
    @lending_item.destroy
    respond_to do |format|
      flash[:success] = 'Item deleted.'
      format.html { redirect_to lending_items_url }
    end
  end

  # ------------------------------------------------------------
  # Helper methods

  def sort_column
    params[:sort].tap { |col| return 'created_at' unless LendingItem.column_names.include?(col) }
  end

  def sort_direction
    params[:direction].tap { |dir| return 'desc' unless %w[asc desc].include?(dir) }
  end

  # ------------------------------------------------------------
  # Private methods

  private

  # ------------------------------
  # Private accessors

  def patron_identifier
    current_user.lending_id
  end

  def lending_admin?
    current_user.lending_admin?
  end

  def eligible_patron?
    current_user.ucb_staff? || current_user.ucb_faculty? || current_user.ucb_student?
  end

  def existing_loan
    @existing_loan ||= active_loan || most_recent_loan
  end

  def active_loan
    @active_loan ||= LendingItemLoan.active.find_by(**loan_args)
  end

  def most_recent_loan
    @most_recent_loan ||= LendingItemLoan.where(**loan_args).order(:updated_at).last
  end

  def available?
    @lending_item_loan.active? || @lending_item.available?
  end

  def reason_unavailable
    return if available?
    return LendingItem::MSG_UNPROCESSED unless @lending_item.processed?
    return LendingItem::MSG_UNAVAILABLE unless (due_date = @lending_item.next_due_date)

    # TODO: format all dates
    "#{LendingItem::MSG_UNAVAILABLE} It will be returned on #{due_date}"
  end

  def manifest_url
    lending_manifest_url(directory: directory)
  end

  # ------------------------------
  # Parameter methods

  # item lookup parameter (pseudo-ID)
  def directory
    params.require(:directory)
  end

  # create/update parameters
  def lending_item_params # TODO: better/more consistent name
    params.permit(:directory, :title, :author, :copies, :processed)
  end

  # loan lookup parameters
  def loan_args # TODO: better/more consistent name
    {
      lending_item: ensure_lending_item!,
      patron_identifier: patron_identifier
    }
  end

  # ------------------------------
  # Utility methods

  def require_lending_admin!
    return if lending_admin?

    raise Error::ForbiddenError, 'This page is restricted to UC BEARS administrators.'
  end

  def require_eligible_patron!
    return if eligible_patron?

    raise Error::ForbiddenError, 'This page is restricted to active UC Berkeley faculty, staff, and students.'
  end

  def require_active_loan!
    require_eligible_patron!

    raise ActiveRecord::RecordNotFound, MSG_NOT_CHECKED_OUT unless active_loan
  end

  def ensure_lending_item!
    @lending_item ||= LendingItem.find_by(directory: directory)
  end

  def ensure_lending_item_loan!
    require_eligible_patron!

    @lending_item_loan = existing_loan || LendingItemLoan.new(**loan_args)
  end

end
# rubocop:enable Metrics/ClassLength
