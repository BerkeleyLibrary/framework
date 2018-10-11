module Submitable
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Callbacks
    include ActiveModel::Model

    # Callbacks configuration
    define_model_callbacks :submit
    before_submit :validate!
  end

  def submit!
    run_callbacks :submit do
      submit
    end
  end

protected

  def submit
    true # Sub-classes should override this method
  end

end
