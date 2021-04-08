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
      @transaction_info += "|FEE#{idx}:#{fine['id']}"
    end
    
    @transaction_info += "|TOTAL:#{@total}"

    #puts "\n\n#{@transaction_info}\n\n"
    # TODO: setup a paypal service to hit paypal api


  end

end
