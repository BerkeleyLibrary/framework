class LendingItemLoansController < ApplicationController
  before_action :set_lending_item_loan, only: %i[show edit update destroy]

  # GET /lending_item_loans or /lending_item_loans.json
  def index
    @lending_item_loans = LendingItemLoan.all
  end

  # GET /lending_item_loans/1 or /lending_item_loans/1.json
  def show; end

  # GET /lending_item_loans/new
  def new
    @lending_item_loan = LendingItemLoan.new
  end

  # GET /lending_item_loans/1/edit
  def edit; end

  # POST /lending_item_loans or /lending_item_loans.json
  def create
    @lending_item_loan = LendingItemLoan.new(lending_item_loan_params)

    respond_to do |format|
      if @lending_item_loan.save
        format.html { redirect_to @lending_item_loan, notice: 'Lending item loan was successfully created.' }
        format.json { render :show, status: :created, location: @lending_item_loan }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @lending_item_loan.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lending_item_loans/1 or /lending_item_loans/1.json
  def update
    respond_to do |format|
      if @lending_item_loan.update(lending_item_loan_params)
        format.html { redirect_to @lending_item_loan, notice: 'Lending item loan was successfully updated.' }
        format.json { render :show, status: :ok, location: @lending_item_loan }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @lending_item_loan.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lending_item_loans/1 or /lending_item_loans/1.json
  def destroy
    @lending_item_loan.destroy
    respond_to do |format|
      format.html { redirect_to lending_item_loans_url, notice: 'Lending item loan was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  def current_patron_identifier
    # TODO: something more secure
    current_user.uid
  end

  def set_lending_item_loan
    @lending_item_loan = LendingItemLoan.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def lending_item_loan_params
    params.require(:lending_item_loan).permit(:lending_item_id, :patron_identifier, :loan_status, :loan_date, :due_date, :return_date)
  end
end
