# NOTE: Date/Time#to_s(format) in Rails views reads time/date formats from config/locales, but
#       in test code it reads from Date/Time::DATE_FORMATS, so we need to make sure it's in both
#       places. Presumably there's some better way this is supposed to work? At least this code
#       makes sure it's consistent.
#
# TODO: Figure out how this is *really* supposed to work

module Framework
  module TimeFormats
    class << self
      KEY_TO_FMTS = { date: Date::DATE_FORMATS, time: Time::DATE_FORMATS }.freeze

      def copy_from_locales!
        locales = YAML.load_file(locales_path).deep_symbolize_keys
        return unless (locale_en = locales[:en])

        KEY_TO_FMTS.each do |key, fmt|
          next unless (ns = locale_en[key])
          next unless (formats = ns[:formats])

          formats.each { |name, val| fmt[name] = val }
        end
      end

      private

      def locales_path
        File.expand_path('../locales/en.yml', __dir__)
      end
    end
  end
end

Framework::TimeFormats.copy_from_locales!
