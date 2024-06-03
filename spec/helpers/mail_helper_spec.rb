require 'rails_helper'

describe MailHelper, type: :helper do

  describe 'a section' do

    it 'returns an expected array' do
      res = [{ theft_personal: 'Theft-personal items' }, { theft_library: 'Theft-library property' }, { vandalism: 'Vandalism-damaged property' },
             { assault: 'Assault' }, { criminal_other: 'Other' }]
      expect(sections('criminal')).to match_array(res)
    end

    it 'returns an empty array' do
      expect(sections('empty')).to be_empty
    end

    it 'returns expected array' do
      res = [{ police_notified: 'Police notified' }]
      expect(sections('police_notified')).to match_array(res)
    end
  end
end
