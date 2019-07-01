require 'test_helper'

class ServiceArticleRequestFormTest < ActiveSupport::TestCase
  setup do
    @form = ServiceArticleRequestForm.new(
      display_name: "Chris Sharma",
      patron: Patron::Record.new(
        id: 111111,
        name: "test-111111",
        type: Patron::Type::FACULTY,
        notes: ["first note", "book scan eligible", "third note"],
      ),
      patron_email: 'chris@sharma.com',
      article_title: 'Es Pontas (9a+)',
      pub_title: 'King Lines',
      vol: '1',
    )
  end

  test "basic form is valid" do
    assert @form.valid?
  end

  test "raises appropriate error when note or patron is missing" do
    @form.patron.notes = []
    assert_raises(Error::PatronNotEligibleError) { @form.valid? }

    @form.patron = nil
    assert_raises(Error::PatronNotFoundError) { @form.valid? }
  end
end
