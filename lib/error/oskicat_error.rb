module Error
  class OskiCatError < StandardError
    def initialize(msg="Couldn't connect to OskiCat. Is the server allowed to connect?")
      super
    end
  end
end
