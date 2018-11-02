class Form
  include ActiveModel::Model

  # Submits the form after strict validation
  # @raise [StandardError] If anything goes wrong (no return values)
  # @return [void]
  def submit!
    validate!
    submit
  end

  private

  # @!method submit
  #   @abstract Subclass should implement {#submit} to perform form submission
  #   @return [void]
end
