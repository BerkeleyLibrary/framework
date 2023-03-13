class HoldingsTask < ActiveRecord::Base

  has_one_attached :input_file
  has_one_attached :output_file

  validates :email, presence: true
  validates :filename, presence: true
  validate :options_selected

  def each_input_oclc(&)
    with_input_tmpfile do |tmpfile|
      reader = BerkeleyLibrary::Holdings::XLSXReader.new(tmpfile.path)
      reader.each_oclc_number(&)
    end
  end

  def with_input_tmpfile(&)
    input_file.open(&)
  end

  private

  def options_selected
    return if rlf || uc || hathi

    errors.add(:base, 'At least one of RLF, Other UC, or HathiTrust must be selected')
  end
end
