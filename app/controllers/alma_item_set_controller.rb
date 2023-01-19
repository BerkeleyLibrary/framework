require 'date'

class AlmaItemSetController < ApplicationController

  # TODO: - Need to make sure only certain staff access this page
  before_action :authorize!

  def index
    # Lookup of all sets for drop-boxes:
    @production_sets = Alma::ItemSet.fetch_set_array 'production'
    @sandbox_sets = Alma::ItemSet.fetch_set_array 'sandbox'
  end

  # rubocop:disable Metrics/AbcSize
  def update
    env = params[:alma_env]
    alma_set_id = params[:alma_set_id]
    num = params[:note_num]

    # Format a new note
    note = new_note(params[:note_value], params[:initials])

    Alma::ItemSet.prepend_note_to_set(env, alma_set_id, note, num, current_user.email)

    # @email_address = current_user.email

    respond_to do |format|
      format.js { render json: current_user.email }
    end
  end
  # rubocop:enable Metrics/AbcSize

  private

  def authorize!
    return if Rails.env.development?

    # TODO - Setup calgroup once Jackie has that configured!
    
    authenticate!
    raise Error::ForbiddenError unless current_user.framework_admin
  end

  def new_note(text, initials)
    "#{Time.zone.today} - #{text} - #{initials}"
  end
end
