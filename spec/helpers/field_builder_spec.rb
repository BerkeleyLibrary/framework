require 'rails_helper'

describe FieldBuilder, type: :helper do
  let(:builder) { instance_double ActionView::Helpers::FormBuilder }

  before do
    mock_model = instance_double AffiliateBorrowRequestForm
    allow(mock_model).to receive_messages(errors: ActiveModel::Errors.new(mock_model),
                                          employee_name: 'string value')
    allow(builder).to receive_messages(label: '', object: mock_model)
    allow(builder).to receive(:text_field) { |name, attrs| content_tag(:input, nil, attrs.merge({ name: })) }
  end

  describe '.field_tag' do
    context 'with required: true' do
      subject(:field) do
        described_class.new(tag_helper: self, builder:, attribute: :employee_name, type: :text_field, required: true,
                            readonly: false, html_options: nil)
      end

      it 'includes the aria-required attribute' do
        expect(field.build).to include('aria-required="true"')
      end
    end

    context 'with required: false' do
      subject(:field) do
        described_class.new(tag_helper: self, builder:, attribute: :employee_name, type: :text_field, required: false,
                            readonly: false, html_options: nil)
      end

      it 'does not include the aria-required attribute' do
        expect(field.build).not_to include('aria-required')
      end
    end

    context 'with html_options' do
      subject(:field) do
        described_class.new(tag_helper: self, builder:, attribute: :employee_name, type: :text_field, required: false,
                            readonly: false, html_options: { placeholder: 'An example placeholder',
                                                             aria: { describedby: 'another_div' } })
      end

      it 'includes the passed options as attributes' do
        expect(field.build).to include('aria-describedby="another_div"')
        expect(field.build).to include('placeholder="An example placeholder"')
      end
    end

    context 'with html_options and required: true' do
      subject(:field) do
        described_class.new(tag_helper: self, builder:, attribute: :employee_name, type: :text_field, required: true,
                            readonly: false, html_options: { placeholder: 'An example placeholder',
                                                             aria: { describedby: 'another_div' } })
      end

      it 'mixes both aria attributes' do
        expect(field.build).to include('aria-describedby="another_div"')
        expect(field.build).to include('aria-required="true"')
      end
    end
  end
end
