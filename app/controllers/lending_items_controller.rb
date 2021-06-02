class LendingItemsController < ApplicationController
  # ------------------------------------------------------------
  # Hooks

  before_action :require_lending_admin!
  before_action :set_lending_item, only: %i[show edit update destroy]

  # ------------------------------------------------------------
  # Controller actions

  # GET /lending_items or /lending_items.json
  def index
    @lending_items = LendingItem.all
  end

  # GET /lending_items/1 or /lending_items/1.json
  def show; end

  # GET /lending_items/new
  def new
    @lending_item = LendingItem.new
  end

  # GET /lending_items/1/edit
  def edit; end

  # POST /lending_items or /lending_items.json
  def create
    @lending_item = LendingItem.new(lending_item_params)

    respond_to do |format|
      if @lending_item.save
        format.html { redirect_to @lending_item, notice: 'Lending item was successfully created.' }
        format.json { render :show, status: :created, location: @lending_item }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @lending_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lending_items/1 or /lending_items/1.json
  def update
    respond_to do |format|
      if @lending_item.update(lending_item_params)
        format.html { redirect_to @lending_item, notice: 'Lending item was successfully updated.' }
        format.json { render :show, status: :ok, location: @lending_item }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @lending_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lending_items/1 or /lending_items/1.json
  def destroy
    @lending_item.destroy
    respond_to do |format|
      format.html { redirect_to lending_items_url, notice: 'Lending item was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  # ------------------------------------------------------------
  # Private methods

  private

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
end
