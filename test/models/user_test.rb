require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup { VCR.insert_cassette 'patrons' }
  teardown { VCR.eject_cassette }

  test 'from_omniauth() populates IDs' do
    employee_id = '12345'
    cs_id       = '67890'
    student_id  = '24680'
    uid         = '13579'

    auth_hash = {
        'provider' => 'calnet',
        'extra'    => {
            'employeeNumber'        => employee_id,
            'berkeleyEduCSID'       => cs_id,
            'berkeleyEduStuID'      => student_id,
            'uid'                   => uid,
            'berkeleyEduIsMemberOf' => []
        }
    }
    user      = User.from_omniauth(auth_hash)

    assert_equal(employee_id, user.employee_id)
    assert_equal(cs_id, user.cs_id)
    assert_equal(student_id, user.student_id)
    assert_equal(uid, user.uid)
  end

  test 'primary_patron_record prefers student_id to employee_id' do
    employee_id = '013191304'
    student_id  = '99999997'

    auth_hash = {
        'provider' => 'calnet',
        'extra'    => {
            'employeeNumber'        => employee_id,
            'berkeleyEduStuID'      => student_id,
            'berkeleyEduIsMemberOf' => []
        }
    }
    user      = User.from_omniauth(auth_hash)
    patron    = user.primary_patron_record
    assert_equal(student_id, patron.id)
  end

  test 'primary_patron_record prefers student_id to cs_id' do
    cs_id      = '013191304'
    student_id = '99999997'

    auth_hash = {
        'provider' => 'calnet',
        'extra'    => {
            'berkeleyEduCSID'       => cs_id,
            'berkeleyEduStuID'      => student_id,
            'berkeleyEduIsMemberOf' => []
        }
    }
    user      = User.from_omniauth(auth_hash)
    patron    = user.primary_patron_record
    assert_equal(student_id, patron.id)
  end

  test 'primary_patron_record prefers cs_id to employee_id' do
    cs_id      = '18273645'
    employee_id = '013191304'

    auth_hash = {
        'provider' => 'calnet',
        'extra'    => {
            'berkeleyEduCSID'       => cs_id,
            'employeeNumber'        => employee_id,
            'berkeleyEduIsMemberOf' => []
        }
    }
    user      = User.from_omniauth(auth_hash)
    patron    = user.primary_patron_record
    assert_equal(cs_id, patron.id)
  end
end