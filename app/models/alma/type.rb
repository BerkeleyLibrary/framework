module Alma
  # Alma does not have PCodes or Ptypes, instead use Alma UserGroups

  class Type
    UNDERGRAD           = 'UNDERGRAD'.freeze
    UNDERGRAD_SLE       = 'UNDERGRADSLE'.freeze
    GRAD_STUDENT        = 'GRADSTUD'.freeze
    FACULTY             = 'FACULTY'.freeze
    MANAGER             = 'EXECUTIVE'.freeze
    LIBRARY_STAFF       = 'LIBSTAFF'.freeze
    STAFF               = 'NONACAD'.freeze
    POST_DOC            = 'UCB POST'.freeze
    VISITING_SCHOLAR    = 'UCBVISSCHOL'.freeze
  end
end
