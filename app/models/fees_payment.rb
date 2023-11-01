# Contains a collection of Fees
class FeesPayment
  include ActiveModel::Model

  attr_accessor :alma_id
  attr_accessor :pp_ref_number
  attr_accessor :fees

  validates :alma_id,
            presence: true

  def initialize(alma_id:, fee_ids: nil)
    @alma_id = alma_id
    @fees = create_fee_list fee_ids
  end

  # Return the total balance for all fees in the FeesPayment Object
  def total_amount
    fees.reduce(0.0) { |total, f| total + f.balance.to_f }
  end

  # Return jsonified array of the fee ids
  def fee_ids
    fees.map(&:id).to_json
  end

  # Credit Alma for each fee in the @fees array
  def credit
    fees.each { |f| f.credit(alma_id, pp_ref_number) }
  end

  private

  # Fetch all user's fees and filter, which is faster than fetching individual fees
  def create_fee_list(fee_ids)
    fees = Fee.where(alma_user_id: alma_id)
    return fees unless fee_ids

    fees.select { |f| fee_ids.include?(f.id) }
  end

end
