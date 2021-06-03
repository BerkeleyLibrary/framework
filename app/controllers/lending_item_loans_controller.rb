class LendingItemLoansController < ApplicationController

  before_action :authenticate!

  def show
    @lending_item_loan = LendingItemLoan.find_by!(
      lending_item_id: lending_item_id,
      patron_identifier: current_user.lending_id
    )
  end

  def new
    @lending_item_loan = LendingItemLoan.new(
      lending_item_id: lending_item_id,
      patron_identifier: current_user.lending_id
    )
  end

  def check_out
    @lending_item_loan = LendingItemLoan.check_out(
      lending_item_id: lending_item_id,
      patron_identifier: current_user.lending_id
    )

    if @lending_item_loan.persisted?
      redirect_to lending_item_loans_path(lending_item_id: lending_item_id), notice: 'Checkout successful.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def return
    @lending_item_loan = LendingItemLoan.find_by!(
      lending_item_id: lending_item_id,
      patron_identifier: current_user.lending_id
    )
    @lending_item_loan.return!

    redirect_to lending_item_loans_path(lending_item_id: lending_item_id), notice: 'Item returned.'
  end

  def lending_item_id
    params.require(:lending_item_id)
  end
end
