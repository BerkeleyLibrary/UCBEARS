require 'jwt'
require 'securerandom'

module Lending
  module BorrowerId

    attr_reader :uid, :ticket

    def initialize(uid:, ticket:)
      @uid = ensure_valid(:uid, uid)
      @ticket = ensure_valid(:ticket, ticket)

    end

    def to_s
      token
    end

    def inspect
      "BorrowerId@#{object_id}(uid: #{uid.inspect}, ticket: #{ticket.inspect})"
    end

    def token
      @token ||= begin
        JWT.encode({ uid: uid, ticket: ticket }, ALGORITHM, hmac_secret)
      end
    end

    def valid_for?(uid:)
      uid == self.uid
    end

    private

    def hmac_secret
      Rails.application.secrets.fetch(:secret_key_base) do
        raise ArgumentError, "Rails secret_key_base not set"
      end
    end

    def ensure_valid(k, value)
      value.to_s.strip.tap do |v|
        raise ArgumentError, "Invalid value #{value.inspect?} for #{k}" if v.blank?
      end
    end

    class << self
      include BerkeleyLibrary::Logging

      ALGORITHM = 'HS256'.freeze

      def create_for(uid)
        BorrowerId.new(uid: uid, ticket: SecureRandom.uuid)
      end

      def from_token(token)
        payload = segments[0]
        BorrowerId.new(uid: payload['uid'], ticket: payload['ticket'])
      rescue DecodeError => e
        raise ArgumentError, "Error reading token #{token.inspect}"
      end

      def valid_for_user(borrower_id, uid:)
        segments = JWT.decode(borrower_id, hmac_secret)
        segments.any? && segments[0]['uid'] == uid
      rescue DecodeError => e
        Logger.error("Error reading borrower ID #{borrower_id.inspect}", e)
        false
      end

      private

      def hmac_secret
        Rails.application.secrets.fetch(:secret_key_base) do
          raise ArgumentError, "Rails secret_key_base not set"
        end
      end

      def payload_from(token)
        segments = JWT.decode(token, hmac_secret)
        raise ArgumentError, "Invalid token; expected #{1} segment, found #{segments.size}" unless segments.size == 1
        segments[0]
      rescue JWT::DecodeError
        raise ArgumentError, "Error reading token #{token.inspect}"
      end
    end
  end
end
