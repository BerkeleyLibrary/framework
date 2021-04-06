
class FinesController < ApplicationController

  # TODO: setup JWT
  # For now I'm just going to pass in the ID as the parameter...
  # eventually though this will be a jwt that will need to be
  # decoded to grab the alama ID
  def index
    alma_id = params[:id] || nil

    #puts "\n\n\n\n#{alma_id}\n\n\n\n"

    # If no Alma ID redirect to error for now....
    if alma_id.nil?
      redirect_to fines_error_path
    end

    # TODO: pull user's fines from Alma

    #@fine_list = Fine.fetch_all(alma_id)
    @fines = Alma::Fines.fetch_all(alma_id)
    status = @fines.status
    puts "-----> #{status} <------"
    body = JSON.parse(@fines.body)
    puts "************** START *******************"
    puts "\n\n#{body['fee'].inspect}\n\n"
    puts "*************** END *****************\n\n"

    body['fee'].each do |f|
      puts "ID: #{f['id']}"
      puts "  TYPE: #{f['type']['desc']}"
      puts "  STATUS: #{f['status']['desc']}"
      puts "  BALANCE: #{f['balance']}"
      puts "  DATE: #{f['creation_time']}"
    end
  end

  def error
  end

end
