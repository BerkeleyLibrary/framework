# Renders the /home page
#
# We'll likely be asked to remove this at some point, but for now it's useful
# to have in development.
class HomeController < ApplicationController
  def admin
    render :admin if require_framework_admin!
  end

  def build_info
    render :build_info
  end

end
