require 'ucblit/tind/api/collection'

class TindDownloadForm < Form
  attr_accessor :user
  attr_accessor :collection

  validates :collection, includes: { in: all_collection_names }

  def root_collections
    @root_collections ||= UCBLIT::TIND::API::Collection.all
  end

  private

  def authorize!
    raise Error::ForbiddenError unless user.staff?
  end

  def all_collection_names
    @all_collection_names ||= [].tap do |names|
      root_collections.each do |root|
        root.each_descendant(include_self: true) do |coll|
          names << coll.name
        end
      end
    end
  end
end
