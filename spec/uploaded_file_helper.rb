module UploadedFileHelper
  class << self
    include UploadedFileHelper
  end

  def uploaded_file_from(source_file, mime_type: nil)
    tmp = Tempfile.new.tap do |t|
      File.open(source_file, 'rb') { |f| IO.copy_stream(f, t) }
      t.rewind
    end

    ActionDispatch::Http::UploadedFile.new(
      tempfile: tmp,
      filename: File.basename(source_file),
      type: mime_type || Marcel::MimeType.for(Pathname.new(source_file))
    )
  end
end
