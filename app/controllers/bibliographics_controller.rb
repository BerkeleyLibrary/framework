class BibliographicsController < ApplicationController
  before_action :authorize!

  def create
    upload_file = params[:upload_file]
    task = Bibliographic::HostBibTask.create_from!(upload_file, current_user.email)
    BibliographicJob.perform_later(task)
    redirect_to bibliographics_index_path
  rescue ActiveModel::ValidationError => e
    catch_upload_errors(e, upload_file.original_filename)
    redirect_to action: :new
  end

  private

  def catch_upload_errors(e, original_filename)
    flash[:alert] = "Issues found in the selected file '#{original_filename}':"
    invalid_errors = e.model.errors.full_messages.join(',')
    flash[:danger] = invalid_errors
  end

  def authorize!
    authenticate!

    # TODO: should this really be open to all UCB staff?
    roles = %i[framework_admin? alma_admin? ucb_staff?]

    # TODO: Unify Framework user roles, these sorts of checks
    raise Error::ForbiddenError unless roles.any? { |role| current_user.send(role) }
  end

end
