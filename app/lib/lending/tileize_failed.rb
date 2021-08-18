module Lending
  class TileizeFailed < StandardError
    def initialize(infile_path, outfile_path, vips_options, cause:)
      msg = "Tileizing #{infile_path} to #{outfile_path} with options: "
      msg << vips_options.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
      msg << "failed with #{cause}"

      super(msg)
    end
  end
end
