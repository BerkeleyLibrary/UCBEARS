module Patron
  # Patron affiliation, per `PCODE1` in the Millennium patron record.
  #
  # See {https://asktico.lib.berkeley.edu/patron-codes/ AskTico} for full list of
  # codes, or ask Lisa Weber, Dave Rez, or Eileen Pinto.
  #
  # @see https://asktico.lib.berkeley.edu/patron-codes/ full list of codes on AskTico
  class Affiliation
    COMMUNITY_COLLEGE = 's'.freeze
    UC_BERKELEY = '0'.freeze
  end
end
