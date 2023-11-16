require_relative 'asset_file'
require_relative 'alma_tind'
module TindMarc
  class BatchCreator

    # rubocop:disable Metrics/MethodLength
    def initialize(args, email)
      @records = []
      @dir = args[:directory].delete_prefix('/')
      @field_336 = args[:resource_type]
      @field_852c = args[:library]
      @field_540a = args[:f_540_a]
      @field_980a = args[:f_980_a]
      @field_982a = args[:f_982_a]
      @field_982b = args[:f_982_b]
      @field_982p = args[:f_982_p]
      @field_991 = args[:restriction]
      @field_902n = args[:initials]
      @email = email
    end
    # rubocop:enable Metrics/MethodLength

    def assets
      AssetFile.new("#{Rails.application.config.tind_data_root_dir}/#{@dir}")
    end

    def alma_id(key)
      key.split('_')[0]
    end

    def prepare
      @t = AlmaTind.new
      if @field_991.empty?
        @t.setup_collection(@field_336, @field_852c, @field_980a, @field_982a, @field_982b,
                            [])
      else
        @t.setup_collection(@field_336, @field_852c, @field_980a, @field_982a, @field_982b,
                            [@field_991])
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def produce_marc(assets)
      assets.file_inventory.each do |key, files|
        alma_id = alma_id(key)
        tind_marc = BerkeleyLibrary::TIND::Mapping::AlmaSingleTIND.new

        url_base = get_url_base(files[0])
        additional_fields = @t.additional_tind_fields(key, files, url_base, @field_902n, @field_980a, @field_540a)
        rec = tind_marc.record(alma_id, additional_fields)
        rec = update_field(rec) unless @field_982p.empty?

        rec = remove_leader_and_namespace(rec.to_xml)
        @records.append rec
      rescue StandardError => e
        Rails.logger.debug "Couldn't create marc record for #{alma_id}. #{e}"
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def create_attachment
      attachment = ''
      @records.each do |rec|
        attachment << rec.to_s
      end
      # puts attachment
      attachment
    end

    def print_out
      Rails.logger.debug @records
      # puts @records
    end

    def send_email
      if @records.empty?
        RequestMailer.tind_marc_batch_email(@email, "No batch records created for #{@dir}", assets.messages).deliver_now
      else
        attachment_name = "#{@field_980a.gsub(/\s/i, '_')}_#{Time.zone.today}.xml"
        RequestMailer.tind_marc_batch_email(@email, "Tind batch load for #{@field_982b}", assets.messages, attachment_name,
                                            create_attachment).deliver_now
      end
    end

    private

    def update_field(rec)
      new_982 = { '982' => { 'p' => @field_982p } }
      BerkeleyLibrary::TIND::Mapping::TindRecordUtil.update_record(rec, new_982)
    end

    def get_url_base(path)
      # Should add this as a config
      url_base = path.gsub('/opt/app/data/da', 'https://digitalassets.lib.berkeley.edu')
      filename = File.basename(path)
      url_base.gsub(filename, '')
    end

    def remove_leader_and_namespace(rec)
      rec = Nokogiri.XML(rec.to_s)
      rec.search('leader').each(&:remove)
      rec.remove_namespaces!
      rec
    end
  end
end
