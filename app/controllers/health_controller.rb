class HealthController < ApplicationController

  # Open health check endpoint, secured by firewall
  def index
    render_check_result
  end

  def render_check_result
    respond_to do |format|
      format.json { render(json: check_result, status: http_status) }
    end
  end

  def check_result
    @check_result ||= Health::Check.new.result
  end

  delegate :http_status, to: :check_result
end
