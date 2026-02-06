require 'date'

class AlmaItemSetController < ApplicationController
  VALID_ENVS = %w[production sandbox].freeze

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
    return head(:bad_request) unless env.in? VALID_ENVS

    alma_set_id = params[:"alma_set_id_#{env}"]
    num = params[:note_num]

    note = new_note(params[:note_value], params[:initials])

    Alma::ItemSet.prepend_note_to_set(env, alma_set_id, note, num, current_user.email)

    respond_to do |format|
      format.js { render json: current_user.email }
    end
  end
  # rubocop:enable Metrics/AbcSize

  private

  def authorize!
    return if Rails.env.development?

    authenticate!
    # raise Error::ForbiddenError unless current_user.framework_admin
    raise Error::ForbiddenError unless current_user.alma_admin
  end

  def new_note(text, initials)
    "#{Time.zone.today} - #{text} - #{initials}"
  end
end
