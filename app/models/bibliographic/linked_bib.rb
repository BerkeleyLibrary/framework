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
      def from_mmsid(host_bib, mms_id)
        marc_record = AlmaServices::Marc.record(mms_id)
        return host_bib.linked_bibs.create(mms_id:, marc_status: 'failed') unless marc_record

        host_bib.linked_bibs.create(mms_id:, marc_status: 'retrieved', ldr_6: ldr_val(6, marc_record),
                                    ldr_7: ldr_val(7, marc_record), field_035: sf_035_val(marc_record))
      end

      private

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
