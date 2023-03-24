RSpec.shared_context('uploaded file') do
  let(:mime_type_xlsx) { BerkeleyLibrary::Util::XLSX::Spreadsheet::MIME_TYPE_OOXML_WB }

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
