module Patron
  # Patron Type Codes
  #
  # Some documentation is {https://asktico.lib.berkeley.edu/patrons-who-have-proxy-server-access/ available online},
  # but your best bet is to ask Lisa Weber, Dave Rez, or Eileen Pinto.
  class Type
    GRAD_STUDENT     = '3'
    FACULTY          = '4'
    MANAGER          = '5'
    LIBRARY_STAFF    = '6'
    STAFF            = '7'
    VISITING_SCHOLAR = '22'
  end
end
