class LendingItemLoansController < ApplicationController
  before_action :authenticate!

  # TODO: add list view

  # TODO: can we get away with just one action & view for new/show?
  def show
    @lending_item_loan = active_loan || LendingItemLoan.order(:updated_at).last
    redirect_to lending_item_loans_new_path(lending_item_id: lending_item_id) unless @lending_item_loan
  end

  # TODO: can we get away with just one action & view for new/show?
  def new
    if active_loan
      flash[:danger] = 'You have already checked out this item.'
      redirect_to lending_item_loans_path(lending_item_id: lending_item_id)

      return
    end
    @lending_item_loan = LendingItemLoan.new(**loan_args)
  end

  def check_out
    @lending_item_loan = LendingItemLoan.check_out(**loan_args)
    render_with_errors(:new, errors) && return unless @lending_item_loan.persisted?

    flash[:success] = 'Checkout successful.'
    redirect_to lending_item_loans_path(lending_item_id: lending_item_id)
  end

  def return
    if active_loan
      active_loan.return!
      flash[:success] = 'Item returned.'
      redirect_to lending_item_loans_new_path(lending_item_id: lending_item_id)
      return
    end

    flash[:danger] = 'You have not checked out this item.'
    redirect_to lending_item_loans_path(lending_item_id: lending_item_id)
  end

  def lending_item_id
    params.require(:lending_item_id)
  end

  private

  def loan_args
    {
      lending_item_id: lending_item_id,
      patron_identifier: current_user.lending_id
    }
  end

  def active_loan
    @active_loan ||= LendingItemLoan.active.find_by(**loan_args)
  end

  def errors
    @lending_item_loan.errors
  end
end
