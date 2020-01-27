class CampusNetworksController < ApplicationController
  layout false

  def index
    @generated = CampusNetwork.generated_ranges
    render formats: :txt, locals: {
      networks: CampusNetwork.all(organization: org_param)
    }
  end

  private

  def org_param
    params.permit(:organization)[:organization]
  end

  def page_header
    if org_param.blank?
      'UCB + LBL IP Addresses'
    else
      "#{org_param.upcase}-only IP Addresses"
    end
  end
  helper_method :page_header
end
