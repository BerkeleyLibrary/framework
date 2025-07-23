require 'rails_helper'
require 'fileutils'

# incoming paths: 1) 'directory_collection/ucb/incoming'; 2) 'flat_collection/incoming2'; 3)'', 4)'directory_collection_no_data'
# when the mmsid_barcode checkbox is checked from interface, mmsid_barcode = '1, otherwise mmsid_barcode = '0'
RSpec.shared_context 'setup',
                     shared_context: :metadata do |batch_path, label_subdir_path = nil, mmsid_tind_info_subdir_path = nil, mmsid_barcode = '0'|
  let(:batch_path_hash) do
    { directory_batch_path: 'directory_collection/ucb/incoming', flat_batch_path: 'flat_collection/incoming2', no_batch_path: '',
      no_digital_data: 'directory_collection_no_data' }
  end
  let(:mmsid_barcode) { mmsid_barcode }
  let(:incoming_path) { batch_path_hash[batch_path] }
  let(:spec_root_path) { Rails.root.join('spec/data/tind_marc/data/da/').to_s.freeze }
  let(:batch_info) { batch_info_stub }
  let(:source_csv_file_paths) { source_file_paths_tobe_copied(label_subdir_path, mmsid_tind_info_subdir_path) }

  before do
    prepare_test_data
  end

  after do
    clr_test_data
  end

  def prepare_test_data
    return if incoming_path.empty?

    FileUtils.cp(source_csv_file_paths, batch_info.da_batch_path)
    batch_info.create_label_hash
  end

  def clr_test_data
    return if incoming_path.empty?

    label_file_path = batch_info.da_batch_label_file_path
    mmsid_tind_file_path = batch_info.da_mmsid_tind_file_path
    rm_files([label_file_path, mmsid_tind_file_path])
  end

  def batch_info_stub
    return if incoming_path.empty?

    hash = { directory: incoming_path, source_data_root_dir: spec_root_path, mmsid_barcode: }
    TindMarc::BatchInfo.new(hash, '(fake_prefix)')
  end

  def source_file_paths_tobe_copied(label_subdir_path, mmsid_tind_info_subdir_path)
    return if incoming_path.empty?

    label_file_path = label_file_tobe_copied(label_subdir_path)
    mmsid_tind_info_path = mmsid_tind_info_file_tobe_copied(mmsid_tind_info_subdir_path)
    [label_file_path, mmsid_tind_info_path].compact
  end

  def mmsid_tind_info_file_tobe_copied(mmsid_tind_info_subdir_path)
    return if mmsid_tind_info_subdir_path.nil?

    filename = TindMarc::Util.create_mmsid_tind_filename(incoming_path)
    File.join(batch_info.da_batch_path, 'csv_files', 'mmsid_tind_info', mmsid_tind_info_subdir_path, filename)
  end

  def label_file_tobe_copied(label_subdir_path)
    return if label_subdir_path.nil?

    File.join(batch_info.da_batch_path, 'csv_files', 'labels', label_subdir_path, 'labels.csv')
  end

  def rm_files(file_paths)
    file_paths.each do |file_path|
      FileUtils.rm_f(file_path)
    end
  end

end

RSpec.shared_context 'setup_with_args',
                     shared_context: :metadata do |batch_path, label_subdir_path = nil, mmsid_tind_info_subdir_path = nil, mmsid_barcode = '0'|
  include_context 'setup', batch_path, label_subdir_path, mmsid_tind_info_subdir_path, mmsid_barcode
  let(:args) { create_args(incoming_path) }
  let(:email) { 'fake@example.edu' }

  def create_args(incomping_path)
    {
      f_540_a: 'Fake statement',
      f_980_a: 'Map Collections',
      f_982_a: 'Air Photos',
      f_982_b: 'Aerial Photographs',
      f_982_p: 'fake_project',
      library: 'Earth Sciences & Map Library',
      initials: 'yz',
      directory: incomping_path,
      restriction: 'Restricted2Sciences',
      resource_type: 'Image',
      source_data_root_dir: spec_root_path,
      mmsid_barcode: '0'
    }
  end
end

RSpec.shared_context 'setup_with_args_and_alma_request',
                     shared_context: :metadata do |batch_path, label_subdir_path = nil, mmsid_tind_info_subdir_path = nil, mmsid_barcode = '0'|
  include_context 'setup_with_args', batch_path,  label_subdir_path, mmsid_tind_info_subdir_path, mmsid_barcode
  let(:alma_url) { 'https://berkeley.alma.exlibrisgroup.com/view/sru/01UCS_BER?maximumRecords=1&operation=searchRetrieve&query=alma.mms_id=991000401929706532&version=1.2' }
  let(:alma_expected_body) { File.read('spec/data/tind_marc/991000401929706532_sru.xml') }

  before do
    stub_request(:get, alma_url)
      .to_return(status: 200, body: alma_expected_body, headers: {})
  end
end

RSpec.shared_context 'setup_with_args_and_tind_request',
                     shared_context: :metadata do |batch_path, label_subdir_path = nil, mmsid_tind_info_subdir_path = nil, mmsid_barcode = '0'|
  include_context 'setup_with_args', batch_path,  label_subdir_path, mmsid_tind_info_subdir_path, mmsid_barcode
  let(:token) { 'fake_token' }
  let(:tind_url) { 'https://digicoll.lib.berkeley.edu/api/v1/search?In=en&p=901:991000401929706532&of=xm' }
  let(:response_double) { instance_double(Net::HTTPResponse) }

  before do
    allow(response_double).to receive_messages(body: { hits: ['281446'], total: 1 }.to_json, code: '200')
    allow(response_double).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
    stub_request(:get, tind_url)
      .with(headers: { 'Authorization' => "Token #{token}" })
      .to_return(status: 200, body: 'fake body')

    allow(Net::HTTP).to receive(:new).and_call_original
    allow_any_instance_of(Net::HTTP).to receive(:request).and_return(response_double)
  end
end
