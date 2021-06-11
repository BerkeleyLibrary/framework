require 'lending'

class LendingProcessItemJob < ApplicationJob
  def perform(lending_item)
    # TODO: avoid queuing multiples of same job
    lending_item.process!
  end
end
