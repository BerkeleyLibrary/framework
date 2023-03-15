class HoldingsTask < ActiveRecord::Base

  has_one_attached :input_file
  has_one_attached :output_file

  has_many :holdings_world_cat_records, dependent: :destroy
  has_many :holdings_hathi_trust_records, dependent: :destroy

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

  def ensure_holdings_records!
    # oclc_numbers = each_input_oclc.to_a
    # attributes = oclc_numbers.map { |oclc_number| { holdings_task_id: id, oclc_number: oclc_number }}

    each_input_oclc do |oclc_number|
      HoldingsWorldCatRecord.find_or_create_by!(holdings_task: self, oclc_number:) if rlf || uc
      HoldingsHathiTrustRecord.find_or_create_by!(holdings_task: self, oclc_number:) if hathi
    end
  end

  private

  def options_selected
    return if rlf || uc || hathi

    errors.add(:base, 'At least one of RLF, Other UC, or HathiTrust must be selected')
  end
end
