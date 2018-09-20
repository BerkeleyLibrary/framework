require 'test_helper'

class PatronTest < ActiveSupport::TestCase
  setup do
    VCR.insert_cassette 'patrons'
  end

  teardown do
    VCR.eject_cassette
  end

  def test_finding_records_by_id
    {
      "12345678" => {
        :affiliation => [:assert_equal, Patron::Affiliation::UC_BERKELEY],
        :blocks => [:refute],
        :email  => [:assert],
        :id     => [:assert_equal, '12345678'],
        :name   => [:assert],
        :type   => [:assert_equal, Patron::Type::FACULTY],
      },
      "87654321" => {
        :affiliation => [:assert_equal, Patron::Affiliation::UC_BERKELEY],
        :blocks => [:assert],
        :email  => [:assert],
        :id     => [:assert_equal, '87654321'],
        :name   => [:assert],
        :type   => [:assert_equal, Patron::Type::FACULTY],
      },
      "12348765" => {
        :affiliation => [:assert_equal, Patron::Affiliation::COMMUNITY_COLLEGE],
        :blocks => [:refute],
        :email  => [:assert],
        :id     => [:assert_equal, '12348765'],
        :name   => [:assert],
        :type   => [:assert_equal, Patron::Type::FACULTY],
      },
      "87651234" => {
        :affiliation => [:assert_equal, Patron::Affiliation::UC_BERKELEY],
        :blocks => [:refute],
        :email  => [:assert],
        :id     => [:assert_equal, '87651234'],
        :name   => [:assert],
        :type   => [:assert_equal, Patron::Type::VISITING_SCHOLAR],
      },
      "18273645" => {
        :affiliation => [:assert_equal, Patron::Affiliation::UC_BERKELEY],
        :blocks => [:refute],
        :email  => [:assert],
        :id     => [:assert_equal, '18273645'],
        :name   => [:assert],
        :type   => [:assert_equal, Patron::Type::GRAD_STUDENT],
      },
    }.each{ |id, attrs| assert_attrs(Patron.find(id), attrs) }
  end

  def test_not_found_returns_nil
    assert_nil Patron.find('does not exist')
  end

  def test_adding_a_note
    patron = Patron.new(id: '123')

    assert_raises(Net::SSH::AuthenticationFailed) { patron.add_note('hello') }

    with_stubbed_ssh(:succeeded) do |ssh|
      patron.add_note('hello')
    end
  end
end
