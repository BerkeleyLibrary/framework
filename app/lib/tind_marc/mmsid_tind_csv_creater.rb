module TindMarc
  class MmsidTindCsvCreater

    attr_reader :errors

    def initialize(batch_info)
      @batch_info = batch_info
      @errors = []
    end

    def rows
      header_row = %w[mmsid_folder_name tind_identification_from_flat_filenames append_to TIND_record_URLs]
      [header_row].concat(rows_from_mmsid_folders).concat(rows_from_mmsid_flat_files).compact
    end

    private

    def rows_from_mmsid_folders
      folder_names = Util.total_mmsid_folders(@batch_info.da_batch_path)
      folder_names.map { |folder_name| foldername_to_row(folder_name) }.compact
    end

    def foldername_to_row(folder_name)
      mmsid = folder_name.split('_')[0].strip
      mmsid_to_row(mmsid, folder_name)
    end

    def rows_from_mmsid_flat_files
      Util.mmsids_from_flat_filenames(@batch_info.da_batch_path).map { |mmsid| mmsid_to_row(mmsid) }
    end

    def mmsid_to_row(mmsid, folder_name = nil)
      result = tind_result(mmsid)
      return if result.nil?

      tind_info = tind_info(result)
      mmsid_info = folder_name.nil? ? ['', mmsid] : [folder_name, '']
      mmsid_info + tind_info
    end

    def tind_info(result)
      return ['', 'No TIND record found'] if result['total'] == 0

      [result['hits'].join(';'), result['hits'].map { |id| tind_record_url(id) }.join(';')]
    end

    # TIND API returns a HTTPSuccess with a code status other than 200
    def tind_result(mmsid)
      url = tind_api_url(mmsid)
      response = tind_api_response(url)
      return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess) && response.code == '200'

      @errors << "Error fetching TIND record on mmsid (#{mmsid}): #{response.message}"
      nil
    end

    def tind_api_response(url)
      initheaders = { 'Authorization' => "Token #{Rails.application.config.tind_api_key}" }
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      req = Net::HTTP::Get.new(uri.request_uri, initheaders)
      http.request(req)
    rescue StandardError => e
      Util.raise_error("Critical error on fetching TIND record: #{e.message}")
    end

    def tind_api_url(mmsid)
      "#{Rails.application.config.tind_base_uri}api/v1/search?In=en&p=901:#{mmsid}&of=xm"
    end

    def tind_record_url(id)
      "#{Rails.application.config.tind_base_uri}record/#{id}?ln=en"
    end

  end
end
