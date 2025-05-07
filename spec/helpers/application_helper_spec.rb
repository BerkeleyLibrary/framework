require 'rails_helper'

describe ApplicationHelper, type: :helper do
  describe '#alerts' do
    context 'with a single flash' do
      subject(:output) { alerts }

      before do
        flash[:success] = 'Congratulations!'
      end

      it 'renders a single div.alert, with a role of status' do
        render html: output
        assert_dom 'div.alert[role=?]', 'status', count: 1
      end
    end

    context 'with multiple flashes' do
      subject(:output) { alerts }

      before do
        flash[:success] = 'Success!'
        flash[:warning] = 'But also warning!'
      end

      it 'renders multiple div.alert elements, each with a role of status' do
        render html: output
        assert_dom 'div.alert[role=?]', 'status', count: 2
      end
    end
  end
end
