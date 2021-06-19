class LendingItemsController < ApplicationController
  # ------------------------------------------------------------
  # Helpers

  helper_method :sort_column, :sort_direction

  # ------------------------------------------------------------
  # Hooks

  before_action :require_lending_admin!, except: :manifest
  before_action :set_lending_item, only: %i[show edit update destroy]

  # ------------------------------------------------------------
  # Controller actions

  # ------------------------------
  # Item actions

  # GET /lending/items
  def index
    @lending_items = LendingItem.order(sort_column + ' ' + sort_direction)
  end

  # GET /lending/items/1
  def show; end

  # GET /lending/items/new
  def new
    @lending_item = LendingItem.new
  end

  # GET /lending/items/1/edit
  def edit; end

  # POST /lending/items
  def create
    @lending_item = LendingItem.new(lending_item_params)
    render_with_errors(:new, errors) && return unless @lending_item.save

    flash[:success] = 'Item created.'
    redirect_to @lending_item
  end

  # PATCH/PUT /lending/items/1
  def update
    render_with_errors(:edit, errors) && return unless @lending_item.update(lending_item_params)

    flash[:success] = 'Item updated.'
    redirect_to @lending_item
  end

  # DELETE /lending/items/1
  def destroy
    @lending_item.destroy
    respond_to do |format|
      flash[:success] = 'Item deleted.'
      format.html { redirect_to lending_items_url }
    end
  end

  # ------------------------------
  # IIIF manifest actions

  # GET /manifests/:record_id/:barcode'
  def manifest
    record_id, barcode = params.require(%i[record_id barcode])
    @lending_item = LendingItem.having_record_id(record_id).find_by!(barcode: barcode)

    # TODO: allow non-admin when checked out?
    raise ActiveRecord::RecordNotFound, "IIIF manifest not found for #{@lending_item.citation}" unless (iiif_item = @lending_item.iiif_item)

    # TODO: cache this, or generate ERB, or something
    manifest = iiif_item.to_manifest(lending_manifests_url(record_id: nil, barcode: nil), image_server_base_uri)
    render(json: manifest)
  end

  # ------------------------------
  # Loan actions

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

  def errors
    @lending_item.errors
  end

  def require_lending_admin!
    authenticate! { |user| return if user.lending_admin? }

    raise Error::ForbiddenError, "Endpoint #{controller_name}/#{action_name} requires Framework lending admin CalGroup"
  end

  def set_lending_item
    @lending_item = LendingItem.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def lending_item_params
    params.require(:lending_item).permit(:barcode, :filename, :title, :author, :millennium_record, :alma_record, :copies)
  end

  # TODO: move this to a utility class
  def image_server_base_uri
    UCBLIT::Util::URIs.uri_or_nil(Rails.application.config.image_server_base_uri).tap do |uri|
      raise ArgumentError, 'image_server_base_uri not set' unless uri
    end
  end
end
