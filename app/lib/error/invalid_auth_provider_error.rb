module Error
  # Raised if someone attempts to authenticate with an invalid provider.
  # TODO: Dubious whether we actually need this?
  class InvalidAuthProviderError < ApplicationError; end
end
