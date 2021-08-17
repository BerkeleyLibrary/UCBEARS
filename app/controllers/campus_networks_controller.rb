class CampusNetworksController < ApplicationController
  layout false

  def index
    @generated = CampusNetwork.ipv6_ranges(org_param)
    render template: 'campus_networks/index.txt', locals: {
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
