require 'jwt'
require 'securerandom'

module Lending
  class BorrowerId

    ALGORITHM = 'HS256'.freeze

    attr_reader :uid, :key

    def initialize(uid:, key:)
      @uid = ensure_non_blank_string(:uid, uid)
      @key = ensure_non_blank_string(:key, key)
    end

    class << self
      def create_for(uid)
        BorrowerId.new(uid: uid, key: SecureRandom.uuid)
      end

      def from_session(borrower_id)
        return borrower_id if borrower_id.is_a?(BorrowerId)
        return unless borrower_id.is_a?(Hash)

        id_hash = borrower_id.with_indifferent_access
        return BorrowerId.new(uid: id_hash[:uid], key: id_hash[:key])
      end
    end

    def to_s
      encoded_id
    end

    alias eql? ==

    def ==(other)
      return false unless other.is_a?(BorrowerId)

      encoded_id == other.encoded_id
    end

    def hash
      encoded_id.hash
    end

    def to_h
      { uid: uid, key: key }
    end

    def inspect
      "BorrowerId@#{object_id}(uid: #{uid.inspect}, key: #{key.inspect})"
    end

    def encoded_id
      @encoded_id ||= begin
        # TODO: BorrowerId: don't use JWT, use something that produces the same result every time
        JWT.encode({ uid: uid }, key, ALGORITHM)
      end
    end

    private

    def ensure_non_blank_string(k, value)
      value.to_s.strip.tap do |v|
        raise ArgumentError, "Invalid value #{value.inspect?} for #{k}" if v.blank?
      end
    end
  end
end
