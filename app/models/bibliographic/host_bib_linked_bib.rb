module Bibliographic
  class HostBibLinkedBib < ActiveRecord::Base
    belongs_to :host_bib
    belongs_to :linked_bib
  end
end
