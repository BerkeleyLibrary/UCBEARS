module Lending
  class ProcessingFailed < StandardError
    def initialize(infile_path, outfile_path, cause:)
      super("Processing #{infile_path} to #{outfile_path} failed with #{cause}")
    end
  end
end
