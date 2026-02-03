module HealthChecks
  class TestItemExists < OkComputer::Check
    include BerkeleyLibrary::Logging

    def check
      if complete_item
        mark_message 'Test item lookup succeeded'
      else
        mark_message 'Unable to locate complete item'
        mark_failure
      end
    rescue StandardError => e
      logger.error(e)
      mark_message 'Error: failed to check item'
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
