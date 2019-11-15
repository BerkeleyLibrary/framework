require 'rails_helper'

describe :campus_networks, type: :request do
  before(:each) do
    stub_request(:get, CampusNetwork.source_url).to_return(
      status: 200,
      body: File.new('spec/data/campusnetworks.html')
    )
    stub_request(:get, CampusNetwork.lbl_url).to_return(
      status: 200,
      body: File.new('spec/data/lblnetworks.html')
    )
  end

  it 'is the :campus_networks path' do
    expect(campus_networks_path).to eq('/campus-networks')
  end

  it 'is the :lbl path' do
    expect(lbl_networks_path).to eq('/lbl-networks')
  end

  it 'returns the list of all IP addresses' do
    get campus_networks_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to match(/UCB \+ LBL IP Addresses/m)
  end

  describe 'result formats' do
    attr_reader :body
    attr_reader :ranges

    before(:each) do
      @ranges = %w[
        128.32.*.*
        136.152.*.*
        169.229.*.*
        192.31.95.*
        192.31.105.*
        192.31.161.*
        192.58.221.*
        192.101.42.*
        192.107.102.*
        10.*.*.*
        198.128.208.*-198.128.223.*
        204.62.155.*
        192.58.231.*
        192.12.173.*
        128.3.*.*
        131.243.*.*
        198.128.16.*-198.128.19.*
        198.125.132.*
        198.125.133.*
        198.128.52.*
        198.128.24.*-198.128.31.*
        198.128.192.*-198.128.207.*
      ]
      get campus_networks_path
      @body = response.body
    end

    it 'returns a comma-delimited list in star format' do
      expect(body).to include(ranges.join(', '))
    end

    it 'returns a newline-delimited list in star format' do
      expect(body).to include(ranges.join("\n"))
    end

    it 'returns "publisher format"' do
      expected = <<~LIST
        128.32.0.0-128.32.255.255
        136.152.0.0-136.152.255.255
        169.229.0.0-169.229.255.255
        192.31.95.0-192.31.95.255
        192.31.105.0-192.31.105.255
        192.31.161.0-192.31.161.255
        192.58.221.0-192.58.221.255
        192.101.42.0-192.101.42.255
        192.107.102.0-192.107.102.255
        10.0.0.0-10.255.255.255
        198.128.208.0-198.128.223.255
        204.62.155.0-204.62.155.255
        192.58.231.0-192.58.231.255
        192.12.173.0-192.12.173.255
        128.3.0.0-128.3.255.255
        131.243.0.0-131.243.255.255
        198.128.16.0-198.128.19.255
        198.125.132.0-198.125.132.255
        198.125.133.0-198.125.133.255
        198.128.52.0-198.128.52.255
        198.128.24.0-198.128.31.255
        198.128.192.0-198.128.207.255
      LIST

      expect(body).to include(expected)
    end

    it 'can filter for LBL only' do
      get campus_networks_path(organization: 'lbl')
      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/LBL-only IP Addresses/m)
    end

    it 'can filter for UCB only' do
      get campus_networks_path(organization: 'ucb')
      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/UCB-only IP Addresses/m)
    end
  end
end
