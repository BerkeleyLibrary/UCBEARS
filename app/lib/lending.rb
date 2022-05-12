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

    def all_final_dirs
      all_stage_dirs(:final)
    end

    def each_processing_dir(&block)
      each_stage_dir(:processing, &block)
    end

    def each_stage_dir(stage, &block)
      return to_enum(:each_stage_dir, stage) unless block_given?

      stage_root = stage_root_path(stage)
      PathUtils.each_item_dir(stage_root, &block)
    end

    def all_stage_dirs(stage)
      stage_root = stage_root_path(stage)
      PathUtils.all_item_dirs(stage_root)
    end
  end
end
