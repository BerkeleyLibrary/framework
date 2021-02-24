class TindDownloadController < AuthenticatedFormController

  private

  def init_form!
    @form = TindDownloadForm.new(user: current_user)
    @form.authorize!
  end

end
