class TindMarcBatch < Form
  extend ActiveModel::Naming
  require 'find'

  REQUIRED_PARAMS = %i[directory f_980_a f_982_a f_982_b f_540_a resource_type library initials verify_tind].freeze
  OPTIONAL_PARAMS = %i[f_982_p restriction].freeze

  validates :directory, :f_980_a, :f_982_a, :f_982_b, :f_540_a, :resource_type, :library, :initials, presence: true
  validate :directory_must_exist
  validate :directory_has_digital_assets

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
