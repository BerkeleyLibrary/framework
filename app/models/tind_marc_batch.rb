class TindMarcBatch < Form
  include ActiveModel::Validations

  attr_reader :params
  attr_accessor :directory, :f_980_a, :f_982_a, :f_982_b, :f_540_a, :resource_type, :library, :email

  REQUIRED_PARAMS = %i[directory f_980_a f_982_a f_982_b f_540_a resource_type library email].freeze
  OPTIONAL_PARAMS = %i[f_982_p restriction].freeze

  # validates_presence_of REQUIRED_PARAMS, allow_blank: false
  validates :directory, :f_980_a, :f_982_a, :f_982_b, :f_540_a, :resource_type, :library, :email, presence: true

  def initialize(params)
    super()
    @params = params
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

end
