# frozen_string_literal: true

module HealthChecks
  CHECK_FILES = %w[
    iiif_item_check
    iiif_server_check
    lending_root_path
    test_item_exists
  ].freeze

  CHECK_FILES.each do |name|
    require File.join(__dir__, "health_checks/#{name}")
  end
end
