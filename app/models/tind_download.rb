require 'ucblit/tind/api/collection'

class TindDownload < Form
  attr_accessor :user
  attr_accessor :collection

  def root_collections
    # TODO: sensible caching mechanism?
    UCBLIT::TIND::API::Collection.all
  end

  def authorize!
    raise Error::ForbiddenError unless user.ucb_staff?
  end
end
