class MmsidTindJob < ApplicationJob
  queue_as :default

  def perform(args, email)
    task = TindMarc::MmsidTindTask.new(args, email)
    task.run
  end

end
