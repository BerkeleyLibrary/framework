class TindValidator < ActiveRecord::Base
  extend ActiveModel::Naming

  # REQUIRED_PARAMS = %i[directory 980__a 982__a 982__b 540__a 336__a 852__c 902__n].freeze
  REQUIRED_PARAMS = %i[980__a 982__a 982__b 540__a 336__a 852__c 902__n].freeze
  OPTIONAL_PARAMS = %i[982__p 991__a directory].freeze

  has_one_attached :input_file
  validate :directory_must_exist
  validate :directory_has_digital_assets

  validates :'980__a', :'982__a', :'982__b', :'336__a', :'540__a', :'852__c', :'902__n', :input_file, presence: true
  validate :correct_mime_type
  # validates :directory, :'980__a', :'982__a', :'982__b', :'336__a', :'540__a', :'852__c', :'902__n', :input_file, presence: true
  # validate :directory_must_exist
  # validate :directory_has_digital_assets

  def initialize(params)
    super()
    @params = params
    @errors = ActiveModel::Errors.new(self)
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

  def correct_mime_type
    error_msg = 'Input file must be a CSV or XLSX file'
    content_types = %w[text/csv application/vnd.openxmlformats-officedocument.spreadsheetml.sheet]
    errors.add(:input_file, error_msg) unless @params[:input_file].content_type.in?(content_types)
  end

  def directory_has_digital_assets
    error_msg = "#{@params[:directory]} has no digital asset files."
    unless (Dir.exist? "#{Rails.application.config.tind_data_root_dir}/#{@params[:directory]}") &&
      Dir.glob("#{Rails.application.config.tind_data_root_dir}/#{@params[:directory]}/**/*.*").empty?
      return
    end

    errors.add(:directory, error_msg)
  end

  def directory_must_exist
    error_msg = 'Path is invalid. It should be a directory path based on a collection root directory. (e.g. librettos/ucb/incoming)'
    errors.add(:directory, error_msg) unless File.directory? "#{Rails.application.config.tind_data_root_dir}/#{@params[:directory]}"
  end

end
