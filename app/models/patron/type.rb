module Patron
  # Patron type, per `PTYPE` in the Millennium patron record.
  #
  # See {https://asktico.lib.berkeley.edu/patron-type/ AskTico} for full list of
  # types, or ask Lisa Weber, Dave Rez, or Eileen Pinto.
  #
  # @see https://asktico.lib.berkeley.edu/patron-type/ full list of types on AskTico
  class Type
    UNDERGRAD           = '1'.freeze
    UNDERGRAD_SLE       = '2'.freeze
    GRAD_STUDENT        = '3'.freeze
    FACULTY             = '4'.freeze
    MANAGER             = '5'.freeze
    LIBRARY_STAFF       = '6'.freeze
    STAFF               = '7'.freeze
    POST_DOC            = '12'.freeze
    LBNL_ACADEMIC_STAFF = '17'.freeze
    VISITING_SCHOLAR    = '22'.freeze
  end
end
