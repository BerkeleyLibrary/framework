module Bibliographic
  class HostBib < ActiveRecord::Base
    belongs_to :host_bib_task
    has_many   :host_bib_linked_bibs, dependent: :destroy
    has_many   :linked_bibs, dependent: :destroy, through: :host_bib_linked_bibs

    enum :marc_status, {
      pending: 0,
      retrieving: 3,
      retrieved: 6,
      failed: 9
    }, default: :pending

    class << self
      def create_linked_bibs(host_bib)
        marc_record = AlmaServices::Marc.record(host_bib.mms_id)
        return host_bib.failed! if marc_record.nil?

        linked_bib_mms_ids = linked_bib_mms_ids_to_process(host_bib, marc_record)
        # to mark the start of retriving linked bibs
        host_bib.retrieving!
        linked_bib_mms_ids.each { |mms_id| Bibliographic::LinkedBib.from_mmsid(host_bib, mms_id) }
        host_bib.retrieved!
      end

      private

      def linked_bib_mms_ids_to_process(host_bib, marc_record)
        status = host_bib.marc_status
        case status
        when 'pending'
          mms_ids_from_744(marc_record)
        when 'retrieving'
          existing_mms_ids = host_bib.linked_bibs.pluck(:mms_id)
          mms_ids_from_744(marc_record) - existing_mms_ids
        end
      end

      def mms_ids_from_744(marc_record)
        subfields = MARC::Spec.find('774$w', marc_record)
        subfields.map(&:value)
      end
    end

    def linked_bibs_failed
      linked_bibs.where(marc_status: 'failed')
    end

    def successful_linked_bibs?
      !linked_bibs.empty? && linked_bibs_failed.empty?
    end

    def without_744?
      linked_bibs.empty?
    end
  end
end
