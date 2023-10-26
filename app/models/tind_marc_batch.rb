class TindMarcBatch < Form
  extend ActiveModel::Naming
  require 'find'

  REQUIRED_PARAMS = %i[directory f_980_a f_982_a f_982_b f_540_a resource_type library email].freeze
  OPTIONAL_PARAMS = %i[f_982_p restriction].freeze

  # validates_presence_of REQUIRED_PARAMS, allow_blank: false
  validates :directory, :f_980_a, :f_982_a, :f_982_b, :f_540_a, :resource_type, :library, presence: true
  validate :directory_must_exist
  validates :email, email: true, presence: true

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

  def directory_must_exist
    error_msg = 'path is invalid. It should point to resources based on a collection root directory. (e.g. librettos/ucb/incoming)'
    errors.add(:directory, error_msg) unless File.directory? "/opt/app/data/da/#{@params[:directory]}"
  end
end
