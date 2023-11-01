class Fee
  include ActiveModel::Model

  attr_accessor :id
  attr_accessor :type
  attr_accessor :date
  attr_accessor :owner
  attr_accessor :balance

  def initialize(alma_fee)
    @id = alma_fee['id']
    @type = alma_fee['type']['desc']
    @date = Date.parse alma_fee['creation_time']
    @owner = alma_fee['owner']['desc']
    @balance = format('%.2f', alma_fee['balance'].to_f) || 0.00
  end

  def credit(alma_user_id, pp_ref_number)
    AlmaServices::Fees.credit(alma_user_id, pp_ref_number, self)
  end

  class << self

    # Fetch all alma fees for user
    def where(alma_user_id:)
      fees = []
      parsed_fees = AlmaServices::Fees.fetch_all(alma_user_id)
      fees = parsed_fees['fee'].map { |f| Fee.new(f) } if parsed_fees['total_record_count'] > 0
      fees
    end

  end
end
