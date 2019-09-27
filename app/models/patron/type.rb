module Patron
  # Patron Type Codes
  #
  # Some documentation is {https://asktico.lib.berkeley.edu/patrons-who-have-proxy-server-access/ available online},
  # but your best bet is to ask Lisa Weber, Dave Rez, or Eileen Pinto.
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
