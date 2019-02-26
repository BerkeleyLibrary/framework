module Patron
  # Patron Type Codes
  #
  # Some documentation is {https://asktico.lib.berkeley.edu/patrons-who-have-proxy-server-access/ available online},
  # but your best bet is to ask Lisa Weber, Dave Rez, or Eileen Pinto.
  class Type
    UNDERGRAD        = '1'
    UNDERGRAD_SLE    = '2'
    GRAD_STUDENT     = '3'
    FACULTY          = '4'
    MANAGER          = '5'
    LIBRARY_STAFF    = '6'
    STAFF            = '7'
    POST_DOC         = '12'
    VISITING_SCHOLAR = '22'
  end
end
