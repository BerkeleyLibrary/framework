class LendingItemLoansController < ApplicationController
  before_action :authenticate!

  MSG_UNAVAILABLE = 'This item is not available.'.freeze

  def show
    @lending_item_loan = existing_loan || LendingItemLoan.new(**loan_args)
    return if @lending_item_loan.active?

    lending_item = @lending_item_loan.lending_item
    return if lending_item.available?

    flash[:danger] = msg_unavailable(lending_item)
  end

  def check_out
    @lending_item_loan = LendingItemLoan.check_out(**loan_args)
    render_with_errors(:show, @lending_item_loan.errors) && return unless @lending_item_loan.persisted?

    flash[:success] = 'Checkout successful.'
    redirect_to lending_item_loans_path(lending_item_id: lending_item_id)
  end

  def return
    if active_loan
      active_loan.return!
      flash[:success] = 'Item returned.'
    else
      flash[:danger] = 'This item is not checked out.'
    end

    redirect_to lending_item_loans_path(lending_item_id: lending_item_id)
  end

  def lending_item_id
    @lending_item_id ||= params.require(:lending_item_id)
  end

  private

  # TODO: format all dates
  def msg_unavailable(lending_item)
    MSG_UNAVAILABLE.dup.tap do |msg|
      next unless (due_date = lending_item.next_due_date)

      msg << " It will be returned on #{due_date}"
    end
  end

  def existing_loan
    @existing_loan ||= active_loan || most_recent_loan
  end

  def loan_args
    @loan_args ||= {
      lending_item_id: lending_item_id,
      patron_identifier: current_user.lending_id
    }
  end

  def active_loan
    @active_loan ||= LendingItemLoan.active.find_by(**loan_args)
  end

  def most_recent_loan
    @most_recent_loan ||= LendingItemLoan.where(**loan_args).order(:updated_at).last
  end

end
