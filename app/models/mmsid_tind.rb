class MmsidTind < Form
  extend ActiveModel::Naming
  require 'find'

  REQUIRED_PARAMS = %i[directory].freeze

  validates :directory, presence: true
  validate :directory_must_exist
  validate :directory_has_digital_assets

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

  # provide tind_data_root_dir based on input parameters
  def permitted_params
    permitted = {}
    REQUIRED_PARAMS.each do |value|
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
