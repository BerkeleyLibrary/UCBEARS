module HealthChecks
  class TestItemExists < OkComputer::Check
    include BerkeleyLibrary::Logging

    ERR_NO_COMPLETE_ITEM = 'Unable to locate complete item'.freeze

    def check
      if complete_item
        mark_message 'Test item lookup succeeded'
      else
        mark_message ERR_NO_COMPLETE_ITEM
        mark_failure
      end
    rescue StandardError => e
      mark_message "Failed to check item: #{e.message}"
      mark_failure
    end

    private

    def active_item
      @active_item ||= Item.active.first
    end

    def inactive_item
      @inactive_item ||= Item.inactive.first
    end

    def complete_item
      @complete_item ||= active_item || inactive_item
    end

  end
end
