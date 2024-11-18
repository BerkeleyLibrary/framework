class TindValidator < Form
  extend ActiveModel::Naming

  BASE_PATH = '/opt/app/data/da/4tind/tind_spreadsheets'.freeze

  REQUIRED_PARAMS = %i[directory 980__a 982__a 982__b 540__a 336__a 852__c 902__n].freeze
  OPTIONAL_PARAMS = %i[982__p 991__a].freeze

  validates :directory, :'980__a', :'982__a', :'982__b', :'336__a', :'540__a', :'852__c', :'902__n', :input_file, presence: true
  validate :directory_must_exist
  # validate :directory_has_digital_assets

  def initialize(params)
    super()
    @params = params

    @errors = ActiveModel::Errors.new(self)
  end

  def file_path
    filename = File.basename(@params[:input_file].tempfile.to_path.to_s)
    FileUtils.move(@params[:input_file].tempfile.to_path.to_s,"#{BASE_PATH}/#{filename}")
    new_path = "#{BASE_PATH}/#{filename}"
  end

  def read_attribute_for_validation(key)
    @params[key]
  end

  def permitted_params
    permitted = {}
    REQUIRED_PARAMS.each do |value|
      permitted[value] = @params[value]
    end

    OPTIONAL_PARAMS.each do |value|
      permitted[value] = @params[value]
    end
    permitted
  end

  private

  def directory_has_digital_assets
    error_msg = "#{@params[:directory]} has no digital asset files."
    unless (Dir.exist? "#{Rails.application.config.tind_data_root_dir}/#{@params[:directory]}") &&
            Dir.glob("#{Rails.application.config.tind_data_root_dir}/#{@params[:directory]}/**/*.*").empty?
      return
    end

    errors.add(:directory, error_msg)
  end

  def directory_must_exist
    error_msg = 'Path is invalid. It should directory path based on a collection root directory. (e.g. librettos/ucb/incoming)'
    errors.add(:directory, error_msg) unless File.directory? "#{Rails.application.config.tind_data_root_dir}/#{@params[:directory]}"
  end
end
