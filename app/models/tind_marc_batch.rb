class TindMarcBatch < Form
  extend ActiveModel::Naming
  require 'find'

  REQUIRED_PARAMS = %i[directory f_980_a f_982_a f_982_b f_540_a resource_type library initials].freeze
  OPTIONAL_PARAMS = %i[f_982_p restriction mmsid_barcode].freeze

  validates :directory, :f_980_a, :f_982_a, :f_982_b, :f_540_a, :resource_type, :library, :initials, presence: true
  validate :directory_must_exist
  validate :directory_has_digital_assets

  # :source_data_root_dir is not provided by the Form.
  # To support RSpec data, the :source_data_root_dir value is defined within the model.
  # During validation, it is temporarily removed, recalculated, and then re-added
  # to the return parameters once form validation is complete.
  def initialize(params)
    super()
    dir_path = params.delete(:source_data_root_dir)
    @tind_data_root_dir = TindMarc::Util.get_source_data_root_dir(dir_path)
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
    permitted[:source_data_root_dir] = @tind_data_root_dir
    permitted
  end

  private

  def directory_has_digital_assets
    error_msg = "#{@params[:directory]} has no digital asset files."
    unless (Dir.exist? "#{@tind_data_root_dir}/#{@params[:directory]}") &&
            Dir.glob("#{@tind_data_root_dir}/#{@params[:directory]}/**/*.*").empty?
      return
    end

    errors.add(:directory, error_msg)
  end

  def directory_must_exist
    error_msg = 'Path is invalid. It should directory path based on a collection root directory. (e.g. librettos/ucb/incoming)'
    errors.add(:directory, error_msg) unless File.directory? "#{@tind_data_root_dir}/#{@params[:directory]}"
  end
end
