class FinesController < ApplicationController
  # Because the silent post coming from paypal doesn't come from a form
  # it this the "result" controller function below needs to do a null_session
  protect_from_forgery with: :null_session

  # TODO: setup JWT
  # For now I'm just going to pass in the ID as the parameter...
  # eventually though this will be a jwt that will need to be
  # decoded to grab the alama ID
  def index
    @alma_id = params[:id] || nil

    # puts "\n\n\n\n#{alma_id}\n\n\n\n"

    # If no Alma ID redirect to error for now....
    redirect_to fines_error_path if @alma_id.nil?

    # TODO: pull user's fines from Alma

    # @fine_list = Fine.fetch_all(alma_id)
    @fines = Alma::Fines.fetch_all(@alma_id)
    status = @fines.status
    # puts "-----> #{status} <------"

    if status == 200
      @fines = JSON.parse(@fines.body)
    else
      redirect_to fines_error_path
    end
    # puts "************** START *******************"
    # puts "\n\n#{body['fee'].inspect}\n\n"
    # puts "*************** END *****************\n\n"

    # @fines['fee'].each do |f|
    #   puts "ID: #{f['id']}"
    #   puts "  TYPE: #{f['type']['desc']}"
    #   puts "  STATUS: #{f['status']['desc']}"
    #   puts "  BALANCE: #{f['balance']}"
    #   puts "  DATE: #{f['creation_time']}"
    # end
  end

  def error; end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  # bit of a misnomer.... really is "confirm payment"
  def payment
    # TODO: refactor the living crap out of this!!!
    # TODO: Get balance for each fee selected and talley up

    @transaction_details = create_transaction(params)

    puts "\n\n*************************"
    # puts "TRANSACTION: \n#{@transaction_details.inspect}\n\n"
    # fee_list = @transaction_details['fines'].map{|fine| fine['id']}.join(':')
    # puts fee_list
    puts "*************************\n\n"

    @transaction_info = ''
    @alma_id = params['user_id']

    @transaction_info += "USER:#{@alma_id}"
    fees = params['fee']['payment']

    @fines = []
    @total = 0

    fees.each_with_index do |f, idx|
      fine_res = Alma::Fines.fetch_fine(@alma_id, f)
      fine = JSON.parse(fine_res.body)
      @fines.push(fine)
      # puts "\n\n--->#{fine['id']}<---"
      # puts "--->#{fine['balance']}<---\n\n"
      @total += fine['balance'] || 0
      @transaction_info += "|FEE#{idx}:[#{fine['id']}][#{fine['balance']}]"
    end

    @transaction_info += "|TOTAL:#{@total}"

    # puts "\n\n#{@transaction_info}\n\n"
    # TODO: setup a paypal service to hit paypal api
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def credit
    # NOT sure just yet how the params/transaction details are going to come to this credit function....
    # Might need to do a bit of an overhaul here...
    alma_id, fees = parse_transaction(params['transaction_info'])

    # I'll need to grab the amount of the fee. If there's some sort of PayPal transaction info, it may be worth throwing
    # it into the comment within Alma.
    fees.each do |f|
      # puts "CREDITING FEE: USER --> #{alma_id} | FEE --> #{f}"
      Alma::Fines.credit_fine(alma_id, f)
    end
  end

  # Might want to move this to a separate 'API' only controller
  def result
    # This should be hit by the silent post from PayPal
    # 1. Parse the post and grab the User's Alma ID and each Fee ID that was paid
    #    I think I can put that data in fields 'USER1' and 'USER2'
    # 2. Credit each fee in Alma
    # 3. Confirm silent post received w/PayPal
    render json: { testing: 'return from result' }
  end

  private

  # The transaction details include:
  #   Patron's alma_id
  #   Total (easy to add up now rather than the view)
  #   Array of fines (note - alma calls them fees)
  def create_transaction(params)
    transaction_details = {}

    transaction_details['alma_id'] = params['user_id']
    transaction_details['total'] = 0
    transaction_details['fines'] = []

    params['fee']['payment'].each_with_index do |f, _idx|
      fine = JSON.parse(Alma::Fines.fetch_fine(transaction_details['alma_id'], f).body)
      transaction_details['total'] += fine['balance']
      transaction_details['fines'].push(fine)
    end

    transaction_details
  end

  # Parse the transaction info and return data:
  # Here's what it looks like right now coming in:
  # USER:10335026|FEE0:3260561070006532|FEE1:3260575710006532|FEE2:3260530530006532|FEE3:3260656920006532|TOTAL:235.0

  # NOTE....This MIGHT be wrapped up in a JWT in the future and require some decoding.
  def parse_transaction(t)
    alma_id = ''
    fees = []
    total = 0
    t.split('|').each do |item|
      key, val = item.split(':')
      alma_id = val if key == 'USER'
      total = val if key == 'TOTAL'
      fees.push(val) if key.match(/FEE\d+/)
    end
    [alma_id, fees, total]
  end
end

# USER:10335026|FEE0:3260561070006532|FEE1:3260575710006532|FEE2:3260530530006532|FEE3:3260656920006532|TOTAL:235.0
