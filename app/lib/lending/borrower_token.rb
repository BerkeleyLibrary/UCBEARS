require 'jwt'
require 'securerandom'

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

    class << self
      ALGORITHM = 'HS256'.freeze

      def decode_or_create(token_str, uid:)
        decoded = from_string(token_str, uid: uid)
        decoded || new_token_for(uid)
      end

      def from_string(token_str, uid:)
        return unless (token = decode(token_str))
        return unless token['uid'] == uid

        new(uid, token['borrower_id'], token_str)
      end

      def new_token_for(uid)
        borrower_id = SecureRandom.uuid
        new(uid, borrower_id, encode(uid, borrower_id))
      end

      def encode(uid, borrower_id)
        JWT.encode({ uid: uid, borrower_id: borrower_id }, hmac_secret, ALGORITHM)
      end

      private

      def hmac_secret
        @hmac_secret ||= Rails.application.secrets.fetch(:secret_key_base) do
          raise ArgumentError, 'Rails secret_key_base not set'
        end
      end

      def decode(token_str)
        return unless token_str
        return if token_str.blank?

        segments = JWT.decode(token_str, hmac_secret)
        segments.any? && segments[0]
      rescue DecodeError => e
        Logger.error("Error reading borrower token #{token_str.inspect}", e)
        nil
      end
    end
  end
end
