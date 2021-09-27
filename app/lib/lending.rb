module Lending
  STAGES = %i[ready processing final].freeze

  MARC_XML_NAME = 'marc.xml'.freeze

  class << self
    def lending_root_path
      Config.lending_root_path
    end

    def stage_root_path(stage)
      lending_root_path.join(stage.to_s)
    end

    def each_final_dir(&block)
      return to_enum(:each_final_dir) unless block_given?

      final_root = stage_root_path(:final)
      PathUtils.each_item_dir(final_root, &block)
    end

    def each_processing_dir(&block)
      return to_enum(:each_processing_dir) unless block_given?

      processing_root = stage_root_path(:processing)
      PathUtils.each_item_dir(processing_root, &block)
    end
  end
end
