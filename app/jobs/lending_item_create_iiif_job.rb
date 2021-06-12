require 'lending'

class LendingItemCreateIIIFJob < ApplicationJob
  def perform(lending_item)
    # TODO: avoid queuing multiples of same job
    lending_item.create_iiif_item!
  end
end
