require 'test_helper'

class I18nTest < ActiveSupport::TestCase
  def test_model_translations
    assert_equal ScanRequestForm.model_name.human, 'Faculty Alt-Media Scanning'
    assert_equal UcopBorrowRequestForm.model_name.human, 'UCOP Employee Borrowing Cards'
  end
end
