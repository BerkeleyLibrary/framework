module Lending
  class ManifestBuilder
    attr_reader :title
    attr_reader :author
    attr_reader :item_dir

    def initialize(title:, author:, item_dir:)
      @title = ensure_non_blank(title, :title)
      @author = ensure_non_blank(author, :author)
      @item_dir = item_dir
    end

    # TODO: move to UCBLIT::Util::Strings
    def ensure_non_blank(str, name)
      return str unless str.blank?

      raise ArgumentError, "Invalid #{name} value: #{str.inspect}"
    end
  end
end
