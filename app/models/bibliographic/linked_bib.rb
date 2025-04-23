module Bibliographic
  class LinkedBib < ActiveRecord::Base
    has_many   :host_bib_linked_bibs, dependent: :destroy
    has_many   :host_bibs, through: :host_bib_linked_bibs

    enum :marc_status, {
      pending: 0,
      retrieved: 6,
      failed: 9
    }, default: :pending

    class << self
      def from_774(host_bib, subfields_from_774)
        mms_id = subfields_from_774['w']
        marc_record = AlmaServices::Marc.record(mms_id)
        code_t = subfields_from_774['t']

        linked_bib = find_or_create_linked_bib(mms_id, marc_record)

        host_bib.host_bib_linked_bibs.create(linked_bib:, code_t:)

        linked_bib
      end

      private

      def find_or_create_linked_bib(mms_id, marc_record)
        LinkedBib.find_or_create_by(mms_id:) do |bib|
          bib.marc_status = marc_record ? 'retrieved' : 'failed'
          bib.ldr_6 = marc_record ? ldr_val(6, marc_record) : nil
          bib.ldr_7 = marc_record ? ldr_val(7, marc_record) : nil
          bib.field_035 = marc_record ? sf_035_val(marc_record) : nil
        end
      end

      def sf_035_val(marc)
        fields_035 = MARC::Spec.find('035$a', marc)
        return '' if fields_035.empty?

        ls = fields_035.map(&:value).grep(/^\(OCoLC\)\d+/)
        ls.empty? ? '' : ls[0]
      end

      def ldr_val(num, marc)
        ls = MARC::Spec.find('LDR', marc)
        ls.empty? ? '' : ls[0][num]
      end
    end
  end
end
