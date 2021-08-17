class Form
  include ActiveModel::Model

  # Submits the form after strict validation
  # @raise [StandardError] If anything goes wrong (no return values)
  # @return [void]
  def submit!
    validate!
    submit
  end

  # Executes all validators marked as "strict", raising whatever exception was
  # specified in the attribute config.
  def authorize!
    self.class.validators.select { |v| v.options[:strict] }.each do |validator|
      validator.attributes.each do |attribute|
        validator.validate_each(self, attribute, send(attribute))
      end
    end
  end
end
