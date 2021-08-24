require 'jwt'
require 'securerandom'
require 'berkeley_library/logging'

module Lending
  class BorrowerToken

    attr_reader :uid, :borrower_id, :token_str

    def initialize(uid, borrower_id, token_str)
      @uid = uid
      @borrower_id = borrower_id
      @token_str = token_str
    end
    private_class_method :new

    def as_json(_options = nil)
      token_str
    end

    def _dump(*_args)
      token_str
    end

    def ==(other)
      return unless other.is_a?(BorrowerToken)

      %i[uid borrower_id token_str].all? { |attr| send(attr) == other.send(attr) }
    end

    alias eql? ==

    def to_s
      token_str
    end

    def inspect
      "BorrowerToken@#{object_id}(#{token_str})"
    end

    class << self
      include BerkeleyLibrary::Logging

      ALGORITHM = 'HS256'.freeze

      def decode_or_create(token_str, uid:)
        decoded = from_string(token_str, uid: uid)
        decoded || new_token_for(uid)
      end

      def from_string(token_str, uid:)
        return unless (unmarshalled = _load(token_str))

        unmarshalled if unmarshalled.uid == uid
      end

      def new_token_for(uid)
        borrower_id = SecureRandom.uuid
        new(uid, borrower_id, encode(uid, borrower_id))
      end

      def encode(uid, borrower_id)
        JWT.encode({ uid: uid, borrower_id: borrower_id }, hmac_secret, ALGORITHM)
      end

      def _load(token_str)
        return unless (token = decode(token_str))

        new(token['uid'], token['borrower_id'], token_str)
      end

      private

      def hmac_secret
        @hmac_secret ||= Rails.application.secrets.fetch(:secret_key_base) { raise ArgumentError, 'Rails secret_key_base not set' }
      end

      def decode(token_str)
        return unless token_str
        raise ArgumentError unless token_str.is_a?(String)
        return if token_str.blank?

        segments = JWT.decode(token_str, hmac_secret)
        segments.any? && segments[0]
      rescue JWT::DecodeError => e
        logger.error("Error reading borrower token #{token_str.inspect}", e)
        nil
      end
    end
  end
end
