require 'test_helper'

class PatronTest < ActiveSupport::TestCase
  setup { VCR.insert_cassette 'patrons' }
  teardown { VCR.eject_cassette }

  PATRONS_EXPECTED_ATTRIBUTES = {
    "99999997" => {
      :faculty? => [:refute],
      :student? => [:assert],
      :type => [:assert_equal, Patron::Type::UNDERGRAD],
    },
    "99999891" => {
      :affiliation => [:assert_equal, Patron::Affiliation::UC_BERKELEY],
      :blocks => [:refute],
      :email  => [:assert_equal, 'test-300852@berkeley.edu'],
      :id     => [:assert_equal, '99999891'],
      :name   => [:assert],
      :notes  => [:assert_equal, [
        "20190202 library book scan eligible [sydr]",
        "20190101 library book scan eligible [sydr]",
      ]],
      :type => [:assert_equal, Patron::Type::POST_DOC],
    },
    "12345678" => {
      :affiliation => [:assert_equal, Patron::Affiliation::UC_BERKELEY],
      :blocks => [:refute],
      :email  => [:assert],
      :faculty? => [:assert],
      :id     => [:assert_equal, '12345678'],
      :name   => [:assert],
      :notes  => [:assert_equal, []],
      :student? => [:refute],
      :type   => [:assert_equal, Patron::Type::FACULTY],
    },
    "87654321" => {
      :affiliation => [:assert_equal, Patron::Affiliation::UC_BERKELEY],
      :blocks => [:assert],
      :email  => [:assert],
      :id     => [:assert_equal, '87654321'],
      :name   => [:assert],
      :notes  => [:assert_equal, []],
      :type   => [:assert_equal, Patron::Type::FACULTY],
    },
    "12348765" => {
      :affiliation => [:assert_equal, Patron::Affiliation::COMMUNITY_COLLEGE],
      :blocks => [:refute],
      :email  => [:assert],
      :id     => [:assert_equal, '12348765'],
      :name   => [:assert],
      :notes  => [:assert_equal, []],
      :type   => [:assert_equal, Patron::Type::FACULTY],
    },
    "87651234" => {
      :affiliation => [:assert_equal, Patron::Affiliation::UC_BERKELEY],
      :blocks => [:refute],
      :email  => [:assert],
      :id     => [:assert_equal, '87651234'],
      :name   => [:assert],
      :notes  => [:assert_equal, []],
      :type   => [:assert_equal, Patron::Type::VISITING_SCHOLAR],
    },
    "18273645" => {
      :affiliation => [:assert_equal, Patron::Affiliation::UC_BERKELEY],
      :blocks => [:refute],
      :email  => [:assert],
      :faculty? => [:refute],
      :id     => [:assert_equal, '18273645'],
      :name   => [:assert],
      :notes  => [:assert_equal, []],
      :student? => [:assert],
      :type   => [:assert_equal, Patron::Type::GRAD_STUDENT],
    },
  }

  PATRONS_EXPECTED_ATTRIBUTES.each do |patron_id, attrs|
    test "patron #{patron_id} has expected attributes" do
      assert_attrs(Patron::Record.find(patron_id), attrs)
    end
  end

  test "configurable_attributes" do
    default_api_base_url = URI.parse("https://dev-oskicatp.berkeley.edu:54620/PATRONAPI/")
    assert_equal Patron::Record.api_base_url, default_api_base_url
    assert_equal Patron::Record.new.api_base_url, default_api_base_url

    default_expect_url = URI.parse("ssh://altmedia@vm161.lib.berkeley.edu/home/altmedia/bin/mkcallnote")
    assert_equal Patron::Record.expect_url, default_expect_url
    assert_equal Patron::Record.new.expect_url, default_expect_url
  end

  test "returns nil if not found" do
    assert_raises(Error::PatronNotFoundError) do
      Patron::Record.find('does not exist')
    end
  end

  test "add_note() method" do
    patron = Patron::Record.new(id: '123', notes: ['foo'])

    assert_equal patron.notes, ['foo']
    with_stubbed_ssh(:succeeded) { patron.add_note('hello') }
    assert_equal patron.notes, ['foo', 'hello']

    assert_raises { patron.add_note('hello') }
  end
end
