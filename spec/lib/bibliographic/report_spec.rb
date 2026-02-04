require 'rails_helper'

module Bibliographic
  RSpec.describe Report do
    let(:host_bib_task) { Bibliographic::HostBibTask.create(filename: 'fake.txt', email: 'test@test.example') }
    let(:report) { described_class.new(host_bib_task, 6) }

    # succeed mmsids for csv content
    let(:mmsid_succeed) { '991080637559706532' }
    let(:mmsid_succeed_with_link_035_nil) { '991080637559706538' }
    let(:mmsid_succeed_with_774t) { '991086326613606532' }

    # mmsids for failed detailed in log content
    let(:mmsid_not_processed) { '991080637559706530' }
    let(:mmsid_failed) { '9910806375597065321' }
    let(:mmsid_succeeded_without_774) { '991080637559706533' }
    let(:mmsid_succeeded_link_failed) { '991080637559706534' }

    before do
      add_host_bibs_retrieving
      add_host_bibs_failed
      add_host_bibs_retrieved_link_succeed
      add_host_bibs_retrieved_link_succeed_link_035_nil
      add_host_bibs_retrieved_without_744
      add_host_bibs_retrieved_with_774t
      add_host_bibs_retrieved_link_failed
    end

    after do
      Bibliographic::HostBibTask.find(host_bib_task.id).destroy if host_bib_task.persisted?
    end

    def add_host_bibs_retrieving
      host_bib_task.host_bibs.create(mms_id: mmsid_not_processed, marc_status: 'retrieving', host_bib_task_id: host_bib_task.id)
    end

    def add_host_bibs_failed
      host_bib_task.host_bibs.create(mms_id: mmsid_failed, marc_status: 'failed', host_bib_task_id: host_bib_task.id)
    end

    def add_host_bibs_retrieved_link_succeed
      host_bib = host_bib_task.host_bibs.create(mms_id: mmsid_succeed, marc_status: 'retrieved', host_bib_task_id: host_bib_task.id)
      host_bib.linked_bibs.create(mms_id: '891080637559706531', marc_status: 'retrieved', field_035: 'C200', ldr_6: 'b', ldr_7: 'n')
    end

    def add_host_bibs_retrieved_link_succeed_link_035_nil
      host_bib = host_bib_task.host_bibs.create(mms_id: mmsid_succeed_with_link_035_nil, marc_status: 'retrieved',
                                                host_bib_task_id: host_bib_task.id)
      host_bib.linked_bibs.create(mms_id: '891080637559706538', marc_status: 'retrieved', field_035: nil, ldr_6: nil, ldr_7: 't')
    end

    def add_host_bibs_retrieved_without_744
      host_bib_task.host_bibs.create(mms_id: mmsid_succeeded_without_774, marc_status: 'retrieved', host_bib_task_id: host_bib_task.id)
    end

    def add_host_bibs_retrieved_with_774t
      host_bib = host_bib_task.host_bibs.create!(
        mms_id: mmsid_succeed_with_774t,
        marc_status: 'retrieved',
        host_bib_task_id: host_bib_task.id
      )
      linked_bib = Bibliographic::LinkedBib.create!(
        mms_id: '991086280586206532',
        marc_status: 'retrieved',
        field_035: '(OCoLC)222378351',
        ldr_6: 'a',
        ldr_7: 't'
      )
      Bibliographic::HostBibLinkedBib.create!(
        host_bib:,
        linked_bib:,
        code_t: 'Zhong yao cai = Zhongyaocai = Journal of Chinese medicinal materials.'
      )
    end

    def add_host_bibs_retrieved_link_failed
      host_bib = host_bib_task.host_bibs.create(mms_id: mmsid_succeeded_link_failed, marc_status: 'retrieved', host_bib_task_id: host_bib_task.id)

      host_bib.linked_bibs.create(mms_id: '891080637559706532', marc_status: 'retrieved', field_035: 'C400', ldr_6: 'c', ldr_7: 'x')
      host_bib.linked_bibs.create(mms_id: '891080637559706533', marc_status: 'failed', field_035: nil, ldr_6: nil,
                                  ldr_7: nil)
      host_bib.linked_bibs.create(mms_id: '891080637559706534', marc_status: 'failed', field_035: nil, ldr_6: nil,
                                  ldr_7: nil)
    end

    it 'creates a csv content' do
      content = CSV.parse(report.csv_content)
      expected_content = <<~CONTENT
        Source MMS ID,774 MMS ID,774$t,LDR/06,LDR/07,035,Count of 774s
        #{mmsid_succeed},891080637559706531,-,b,n,C200,1
        #{mmsid_succeed_with_link_035_nil},891080637559706538,-,-,t,-,1
        #{mmsid_succeed_with_774t},991086280586206532,Zhong yao cai = Zhongyaocai = Journal of Chinese medicinal materials.,a,t,(OCoLC)222378351,1
      CONTENT
      expect(content).to eq(CSV.parse(expected_content))
    end

    it 'creates a log content' do
      log_content = report.log_content
      expected_content = <<~CONTENT
        Total 6 Source MMS IDs:
        3 successed,#{' '}
        4 failed, please see details below:#{' '}


        --------------------------------------------------
        1. Source MMS ID #{mmsid_failed} - no Alma retrieved
        2. Source MMS ID #{mmsid_succeeded_without_774} - Alma retrieved without 774's MMS ID
        3. Source MMS ID #{mmsid_succeeded_link_failed} Alma retrieved, but:

          774 MMS ID 891080637559706533 - no Alma retrieved
          774 MMS ID 891080637559706534 - no Alma retrieved

        4. Below Source MMS IDs not processed. You may re-upload them:

        #{mmsid_not_processed}
      CONTENT
      expect(log_content.strip).to eq(expected_content.strip)
    end

    it 'export csv and log file to local' do
      report.save_to_local
      report_file = Rails.root.join('tmp', 'bib', 'output.csv')
      log_file = Rails.root.join('tmp', 'bib', 'log.txt')
      expect(report_file).to be_present
      expect(log_file).to be_present
    end

  end

end
