require 'ucblit/marc'
require 'ucblit/logging'
require 'lending/tileizer'
require 'lending/path_utils'
require 'lending/marc_metadata'

module Lending
  class Processor
    include UCBLIT::Logging

    MARC_XML_NAME = 'marc.xml'.freeze
    MILLENNIUM_RECORD_RE = /^(?<bib>b[0-9]{8})(?<check>[0-9a-z])?$/.freeze

    attr_reader :indir, :outdir, :record_id, :barcode, :marc_path

    def initialize(indir, outdir)
      @indir = PathUtils.ensure_dirpath(indir)
      @outdir = PathUtils.ensure_dirpath(outdir)
      @record_id, @barcode = PathUtils.decompose_dirname(@indir)

      raise ArgumentError, "#{indir}: MARC record not found" unless (@marc_path = find_marc_path)
    end

    def author
      marc_metadata.author
    end

    def title
      marc_metadata.title
    end

    def process!
      tileize_images!
      copy_ocr_text!
      copy_marc_record!
      manifest = write_manifest!
      verify(manifest)
    end

    def to_s
      @s ||= "#{self.class.name.split('::').last}@#{object_id}"
    end

    def verify(manifest)
      raise ArgumentError, 'Manifest never written' unless manifest
      raise ArgumentError, "Manifest template not present in processing directory #{manifest.dir_path}" unless manifest.has_template?
    end

    private

    def marc_metadata
      return @marc_metadata if instance_variable_defined?(:@marc_metadata)

      @marc_metadata = MarcMetadata.from_file(marc_path)
    end

    def tileize_images!
      logger.info("#{self}: tileizing images from #{indir} to #{outdir}")
      Tileizer.tileize_all(indir, outdir)
    end

    def copy_ocr_text!
      logger.info("#{self}: copying OCR text from #{indir} to #{outdir}")
      input_txts.each do |input_txt|
        output_txt = outdir.join(input_txt.basename)
        logger.info("Copying #{input_txt} to #{output_txt}")
        FileUtils.cp(input_txt.to_s, output_txt.to_s)
      end
    end

    def input_txts
      @input_txts ||= indir.children.filter_map do |p|
        next unless PathUtils.image_ext?(p)

        txt_path = PathUtils.txt_path_from(p)
        txt_path if txt_path.exist?
      end
    end

    def copy_marc_record!
      output_marc_path = outdir.join(MARC_XML_NAME)
      logger.info("#{self}: copying #{marc_path} to #{output_marc_path}")
      FileUtils.cp(marc_path, output_marc_path)
    end

    def write_manifest!
      logger.info("#{self}: writing manifest template to #{outdir}")
      IIIFManifest.new(title: title, author: author, dir_path: outdir).tap(&:write_manifest_erb!)
    end

    def find_marc_path
      record_id_lower = record_id.downcase

      indir.children.find do |p|
        next false unless PathUtils.xml_ext?(p)

        stem = PathUtils.stem(p).downcase
        next true if stem == 'marc' || stem == record_id_lower

        stem =~ MILLENNIUM_RECORD_RE && stem.start_with?(record_id_lower) || record_id_lower.start_with?(stem)
      end
    end

  end
end
