require 'jaro_winkler'

class TindDownloadController < ApplicationController

  # ############################################################
  # Constants

  CACHE_EXPIRY = 5.minutes

  NAME_MATCH_COUNT = 15

  # ############################################################
  # Callbacks

  before_action :authorize!

  # ############################################################
  # Actions

  def index
    render locals: { root_collections: root_collections }
  end

  # TODO: require a collection
  # TODO: validate that collection exists (TIND will just 500 on us)
  # TODO: prompt w/collection name & number of records
  # TODO: figure out how to update the page after downloading
  def download
    # TODO: Is there any way to 'start' the downlod before we actually
    #       build the data, so the user thinks something's happening?
    data = UCBLIT::TIND::Export.export_libreoffice(collection_name)
    send_data(
      data,
      filename: "#{collection_name.parameterize}.ods",
      type: 'application/vnd.oasis.opendocument.spreadsheet'
    )
  end

  def find_collection
    term = params[:term]
    render json: find_nearest(term)
  end

  private

  def authorize!
    # TODO: is there a cleaner way to do this?
    return if Rails.env.development?

    authenticate!

    raise Error::ForbiddenError unless current_user.ucb_staff?
  end

  # @return [Array<UCBLIT::TIND::API::Collection>] the root collections
  def root_collections
    Rails.cache.fetch(:tind_root_collections, expires_in: CACHE_EXPIRY) { UCBLIT::TIND::API::Collection.all }
  end

  def collections_by_name
    Rails.cache.fetch(:tind_collections_by_name, expires_in: CACHE_EXPIRY) do
      {}.tap do |coll_by_name|
        root_collections.each do |root|
          root.each_descendant(include_self: true) do |coll|
            coll_by_name[coll.name] = coll
          end
        end
      end
    end
  end

  def collection_names
    Rails.cache.fetch(:tind_collection_names, expires_in: CACHE_EXPIRY) { collections_by_name.keys.sort }
  end

  def find_nearest(term)
    normalized_term = term.parameterize
    distances = [].tap do |d|
      collection_names.each do |name|
        normalized_name = name.parameterize
        distance = JaroWinkler.distance(normalized_term, normalized_name)
        d << [distance, name] if normalized_name.include?(normalized_term)
      end
    end
    distances = distances.sort_by { |k, v| [-k, v] }
    distances[0...NAME_MATCH_COUNT].map { |_, v| v }
  end

  def collection_name
    params[:collection_name]
  end

end
