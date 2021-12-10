module Lending
  class MarcMetadata

    # ------------------------------------------------------------
    # Accessors

    attr_reader :marc_record

    # ------------------------------------------------------------
    # Initializer

    def initialize(marc_record)
      @marc_record = marc_record
    end

    class << self
      include BerkeleyLibrary::Logging

      def from_file(marc_path)
        nil.tap do
          return load_marc_record(marc_path)
        rescue StandardError => e
          logger.warn(e.message)
        end
      end

      private

      def load_marc_record(marc_path)
        marc_record = MARC::XMLReader.read(marc_path.to_s, freeze: true).first
        return MarcMetadata.new(marc_record) if marc_record
      end
    end

    # ------------------------------------------------------------
    # Synthetic accessors

    def author
      @author ||= author_personal || author_corporate
    end

    def title
      @title ||= clean_value(find_title)
    end

    def publisher
      return @publisher if instance_variable_defined?(:@publisher)

      @publisher = find_publisher
    end

    def physical_desc
      return @physical_desc if instance_variable_defined?(:@physical_desc)

      @physical_desc = find_physical_desc
    end

    # ------------------------------------------------------------
    # Private methods

    private

    # ------------------------------
    # Private accessors

    def author_personal
      return @author_personal if instance_variable_defined?(:@author_personal)

      @author_personal = clean_value(find_author_personal)
    end

    def author_corporate
      return @author_corporate if instance_variable_defined?(:@author_corporate)

      @author_corporate = clean_value(find_author_corporate)
    end

    # ------------------------------
    # MARC lookup

    def find_title
      df = find_tag('245')
      return unless df

      join_subfields(df, %w[a b])
    end

    def find_author_personal
      df = find_tag('100') || find_tag('700')
      return unless df

      join_subfields(df, %w[a b c d])
    end

    def find_author_corporate
      df = find_tag('110') || find_tag('710')
      return unless df

      join_subfields(df, %w[a b c d])
    end

    def find_publisher
      df = find_tag('260') || find_tag('264')
      return unless df

      join_subfields(df, %w[a b c d])
    end

    def find_physical_desc
      df = find_tag('300')
      return unless df

      join_subfields(df, %w[a b c])
    end

    # ------------------------------
    # Utility methods

    def join_subfields(df, codes)
      codes.map { |code| df[code] }.compact.map(&:strip).join(' ')
    end

    def find_tag(tag)
      data_fields_by_tag[tag]&.first
    end

    def clean_value(v)
      v && v.strip.sub(%r{[ ,/:;]+$}, '')
    end

    def data_fields_by_tag
      @data_fields_by_tag ||= marc_record.data_fields_by_tag
    end

  end
end
