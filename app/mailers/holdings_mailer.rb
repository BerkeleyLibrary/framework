class HoldingsMailer < ApplicationMailer
  def holdings_results(task)
    headers(
      to: task.email,
      subject: 'Your holdings request'
    )

    blob = task.output_file.blob
    attachments[task.output_filename] = {
      mime_type: blob.content_type,
      content: blob.download
    }

    mail do |format|
      locals = { holdings_task: task }
      format.html { render(locals:) }
      format.text { render(locals:) }
    end
  end
end
