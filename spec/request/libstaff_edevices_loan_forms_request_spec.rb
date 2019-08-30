require 'calnet_helper'

describe :libstaff_edevices_loan_form, type: :request do
  it 'redirects to login' do
    expected_location = login_path(url: new_libstaff_edevices_loan_form_path)
    get new_libstaff_edevices_loan_form_path
    expect(response).to redirect_to(expected_location)
  end

  allowed_patron_types = [
    Patron::Type::LIBRARY_STAFF
  ]

  forbidden_patron_types = Patron::Type.all.reject { |t| allowed_patron_types.include?(t) }

  allowed_patron_types.each do |type|
    it "allows #{Patron::Type.name_of(type)}" do
      patron_id = Patron::Type.sample_id_for(type)
      with_login(patron_id) do
        get new_libstaff_edevices_loan_form_path
        expect(response).to have_http_status(:ok)
      end
    end
  end

  forbidden_patron_types.each do |type|
    it "forbids #{Patron::Type.name_of(type)}" do
      patron_id = Patron::Type.sample_id_for(type)
      with_login(patron_id) do
        get new_libstaff_edevices_loan_form_path
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  it 'forbids users without patron records' do
    patron_id = 'does not exist'
    with_login(patron_id) do
      get new_libstaff_edevices_loan_form_path
      expect(response).to have_http_status(:forbidden)
      expected_msg = /Your patron record cannot be found/
      expect(response.body).to match(expected_msg)
    end
  end

  describe 'with a valid user' do
    attr_reader :patron_id
    attr_reader :patron
    attr_reader :user

    before(:each) do
      @patron_id = Patron::Type.sample_id_for(Patron::Type::LIBRARY_STAFF)
      @user = login_as(patron_id)

      @patron = Patron::Record.find(patron_id)
    end

    after(:each) do
      logout!
    end

    it 'handles patron API errors' do
      expect(Patron::Record).to receive(:find).with(patron_id).and_raise(Error::PatronApiError)
      get new_libstaff_edevices_loan_form_path
      expect(response).to have_http_status(:service_unavailable)
    end

    it 'respects patron blocks' do
      expect(Patron::Record).to receive(:find).with(patron_id).and_return(patron)
      expect(patron).to receive(:blocks).and_return('block all the things')
      get new_libstaff_edevices_loan_form_path
      expect(response).to have_http_status(:forbidden)
    end

    it 'rejects a submission with missing fields' do
      post('/forms/library-staff-devices', params: {
             libstaff_edevices_loan_form: {}
           })
      expect(response).to redirect_to(new_libstaff_edevices_loan_form_path)
    end

    it 'accepts a submission' do
      post('/forms/library-staff-devices', params: {
             libstaff_edevices_loan_form: {
               borrow_check: 'checked',
               edevices_check: 'checked',
               fines_check: 'checked',
               lending_check: 'checked'
             }
           })
      expect(response).to redirect_to('/forms/library-staff-devices/all_check')
    end

    it 'redirects from :index to :new' do
      get libstaff_edevices_loan_forms_path
      expect(response).to redirect_to(new_libstaff_edevices_loan_form_path)
    end

    it 'redirects from :show to :new' do
      some_meaningless_id = Time.now.to_i.to_s
      get libstaff_edevices_loan_form_path(some_meaningless_id)
      expect(response).to redirect_to(new_libstaff_edevices_loan_form_path)
    end
  end
end
