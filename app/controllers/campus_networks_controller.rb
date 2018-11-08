class CampusNetworksController < ApplicationController
  layout false

  def index
    render content_type: 'text/plain', locals: {
      networks: CampusNetwork.all,
    }
  end

  def show
    render :index, content_type: 'text/plain', locals: {
      networks: CampusNetwork.all.select do |network|
        network.organization == network_params[:id].to_sym
      end,
    }
  end

  private

  def page_header
    case network_params[:id]
      when "ucb" then 'UCB-only IP Addresses'
      when "lbl" then 'LBL-only IP Addresses'
                 else 'UCB + LBL IP Addresses'
    end
  end
  helper_method :page_header

  def network_params
    params.permit(:id)
  end
end
