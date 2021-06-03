class LendingItemLoansController < ApplicationController

  before_action :authenticate!

  def show
    @lending_item_loan = LendingItemLoan.find_by!(**loan_args)
  end

  def new
    @lending_item_loan = LendingItemLoan.new(**loan_args)
  end

  def check_out
    @lending_item_loan = LendingItemLoan.check_out(**loan_args)
    render_with_errors(:new, errors) && return unless @lending_item_loan.persisted?

    flash[:success] = 'Checkout successful.'
    redirect_to lending_item_loans_path(lending_item_id: lending_item_id)
  end

  def return
    @lending_item_loan = LendingItemLoan.find_by!(
      lending_item_id: lending_item_id,
      patron_identifier: current_user.lending_id
    )
    @lending_item_loan.return!

    flash[:success] = 'Item returned.'
    redirect_to lending_item_loans_path(lending_item_id: lending_item_id)
  end

  def lending_item_id
    params.require(:lending_item_id)
  end

  def loan_args
    {
      lending_item_id: lending_item_id,
      patron_identifier: current_user.lending_id
    }
  end

  private

  def errors
    @lending_item_loan.errors
  end
end
