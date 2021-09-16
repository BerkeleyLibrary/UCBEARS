class HealthController < ApplicationController

  # Open health check endpoint, secured by firewall
  def index
    render_check_result
  end

  # Admin-only health check endpoint
  def secure
    require_lending_admin!

    render_check_result
  end

  private

  def render_check_result
    respond_to do |format|
      format.json { render(json: check_result, status: http_status) }
    end
  end

  def check_result
    @check_result ||= Health::Check.new.result
  end

  def http_status
    check_result.http_status
  end
end
