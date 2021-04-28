class FinesController < ApplicationController

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
  def payment
    # TODO: refactor the living crap out of this!!!
    # TODO: Get balance for each fee selected and talley up

    @transaction_info = ''
    alma_id = params['user_id']

    @transaction_info += "USER:#{alma_id}"
    fees = params['fee']['payment']

    @fines = []
    @total = 0

    fees.each_with_index do |f, idx|
      fine_res = Alma::Fines.fetch_fine(alma_id, f)
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
    alma_id, fees, total = parse_transaction(params['transaction_info'])
    
    fees.each do |f|
      puts "CREDITING FEE: USER --> #{alma_id} | FEE --> #{f}"
      fine_res = Alma::Fines.credit_fine(alma_id, f)
      
      # TODO: re-implement once I work out the amount....
      # fine = JSON.parse(fine_res.body)
      
      # !!! If ERROR
      # {"errorsExist"=>true, "errorList"=>{"error"=>[{"errorCode"=>"401666", "errorMessage"=>"op parameter is not valid.", "trackingId"=>"E02-2204190346-LWZGI-AWAE101735523"}]}, "result"=>nil}
      # {"errorsExist"=>true, "errorList"=>{"error"=>[{"errorCode"=>"401666", "errorMessage"=>"amount parameter is not valid.", "trackingId"=>"E02-2204195419-WSC4F-AWAE954966549"}]}, "result"=>nil}
      # If success:
      # {"id"=>"3260530530006532", "type"=>{"value"=>"DAMAGEDITEMFINE", "desc"=>"Damaged item fine"}, "status"=>{"value"=>"ACTIVE", "desc"=>"Active"}, "user_primary_id"=>{"value"=>"10335026", "link"=>"https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10335026"}, "balance"=>9.0, "remaining_vat_amount"=>0.0, "original_amount"=>10.0, "original_vat_amount"=>0.0, "creation_time"=>"2021-04-03T19:59:36.257Z", "status_time"=>"2021-04-22T19:56:52.717Z", "comment"=>nil, "owner"=>{"value"=>"MAIN", "desc"=>"Doe Library"}, "title"=>nil, "barcode"=>nil, "transaction"=>[{"type"=>{"value"=>"PAYMENT", "desc"=>"Payment"}, "amount"=>1.0, "vat_amount"=>0.0, "comment"=>"Test1", "created_by"=>"Ex Libris", "external_transaction_id"=>"10006532", "transaction_time"=>"2021-04-22T19:56:52.595Z", "received_by"=>{"value"=>"Not At Desk", "desc"=>"Doe Library"}, "payment_method"=>{"value"=>"ONLINE", "desc"=>"Online"}}], "link"=>"https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10335026/fees/3260530530006532"}
      # {"id"=>"3260530530006532", "type"=>{"value"=>"DAMAGEDITEMFINE", "desc"=>"Damaged item fine"}, "status"=>{"value"=>"ACTIVE", "desc"=>"Active"}, "user_primary_id"=>{"value"=>"10335026", "link"=>"https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10335026"}, "balance"=>8.0, "remaining_vat_amount"=>0.0, "original_amount"=>10.0, "original_vat_amount"=>0.0, "creation_time"=>"2021-04-03T19:59:36.257Z", "status_time"=>"2021-04-22T21:46:30.344Z", "comment"=>nil, "owner"=>{"value"=>"MAIN", "desc"=>"Doe Library"}, "title"=>nil, "barcode"=>nil, "transaction"=>[{"type"=>{"value"=>"PAYMENT", "desc"=>"Payment"}, "amount"=>1.0, "vat_amount"=>0.0, "comment"=>"Test1", "created_by"=>"Ex Libris", "external_transaction_id"=>"10006532", "transaction_time"=>"2021-04-22T19:56:52.595Z", "received_by"=>{"value"=>"Not At Desk", "desc"=>"Doe Library"}, "payment_method"=>{"value"=>"ONLINE", "desc"=>"Online"}}, {"type"=>{"value"=>"PAYMENT", "desc"=>"Payment"}, "amount"=>1.0, "vat_amount"=>0.0, "comment"=>"Test2", "created_by"=>"Ex Libris", "external_transaction_id"=>"NA", "transaction_time"=>"2021-04-22T21:46:30.344Z", "received_by"=>{"value"=>"Not At Desk", "desc"=>"Doe Library"}, "payment_method"=>{"value"=>"ONLINE", "desc"=>"Online"}}], "link"=>"https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10335026/fees/3260530530006532"}
      # When payed in full:
      # {"id"=>"3260530530006532", "type"=>{"value"=>"DAMAGEDITEMFINE", "desc"=>"Damaged item fine"}, "status"=>{"value"=>"CLOSED", "desc"=>"Closed"}, "user_primary_id"=>{"value"=>"10335026", "link"=>"https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10335026"}, "balance"=>0.0, "remaining_vat_amount"=>0.0, "original_amount"=>10.0, "original_vat_amount"=>0.0, "creation_time"=>"2021-04-03T19:59:36.257Z", "status_time"=>"2021-04-22T23:33:39.671Z", "comment"=>nil, "owner"=>{"value"=>"MAIN", "desc"=>"Doe Library"}, "title"=>nil, "barcode"=>nil, "transaction"=>[{"type"=>{"value"=>"PAYMENT", "desc"=>"Payment"}, "amount"=>1.0, "vat_amount"=>0.0, "comment"=>"Test1", "created_by"=>"Ex Libris", "external_transaction_id"=>"10006532", "transaction_time"=>"2021-04-22T19:56:52.595Z", "received_by"=>{"value"=>"Not At Desk", "desc"=>"Doe Library"}, "payment_method"=>{"value"=>"ONLINE", "desc"=>"Online"}}, {"type"=>{"value"=>"PAYMENT", "desc"=>"Payment"}, "amount"=>1.0, "vat_amount"=>0.0, "comment"=>"Test2", "created_by"=>"Ex Libris", "external_transaction_id"=>"NA", "transaction_time"=>"2021-04-22T21:46:30.344Z", "received_by"=>{"value"=>"Not At Desk", "desc"=>"Doe Library"}, "payment_method"=>{"value"=>"ONLINE", "desc"=>"Online"}}, {"type"=>{"value"=>"PAYMENT", "desc"=>"Payment"}, "amount"=>8.0, "vat_amount"=>0.0, "comment"=>"Test2", "created_by"=>"Ex Libris", "external_transaction_id"=>"NA", "transaction_time"=>"2021-04-22T23:33:39.671Z", "received_by"=>{"value"=>"Not At Desk", "desc"=>"Doe Library"}, "payment_method"=>{"value"=>"ONLINE", "desc"=>"Online"}}], "link"=>"https://api-na.hosted.exlibrisgroup.com/almaws/v1/users/10335026/fees/3260530530006532"}


      #puts "\n\nFINE:\n#{fine.inspect}\n\n"
      # puts "\nFINE:\n#{fine['status']['desc']}"
      # puts "\nCOMMENT:\n#{fine['comment'] || 'N/A '}"
    end
    puts "\n\n"

  end

  private

  def create_transaction()
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
    return alma_id, fees, total
  end


end


# USER:10335026|FEE0:3260561070006532|FEE1:3260575710006532|FEE2:3260530530006532|FEE3:3260656920006532|TOTAL:235.0