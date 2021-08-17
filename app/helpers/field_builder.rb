require 'action_view/helpers/tag_helper'

class FieldBuilder
  attr_reader :tag_helper
  attr_reader :builder
  attr_reader :attribute
  attr_reader :type
  attr_reader :required
  attr_reader :readonly

  # Builds a form field with appropriate label and CSS styling
  #
  # @param tag_helper [ActionView::Helpers::TagHelper] enclosing tag helper
  # @param builder [ActionView::Helpers::FormBuilder] enclosing form builder
  # @param attribute [Symbol] attribute name
  # @param type [Symbol] field type
  # @param required [Boolean] true if field is required, false otherwise (default false)
  # @param readonly [Boolean] true if field is read-only, false otherwise (default false)
  # rubocop:disable Metrics/ParameterLists
  def initialize(tag_helper:, builder:, attribute:, type:, required:, readonly:)
    @tag_helper = tag_helper
    @builder = builder
    @attribute = attribute
    @type = type
    @required = required
    @readonly = readonly
  end
  # rubocop:enable Metrics/ParameterLists

  # Builds a form field with appropriate label and CSS styling
  #
  # @return [ActiveSupport::SafeBuffer] A content tag for the field
  def build
    content_tag(:div, class: outer_css) do
      concat label_tag
      concat inner_div
    end
  end

  private

  delegate :content_tag, to: :tag_helper
  delegate :concat, to: :tag_helper

  def field_tag
    @field ||= builder.send(type, attribute, {
                              class: css_class,
                              required: required,
                              readonly: readonly
                            })
  end

  def label_tag
    @label ||= builder.label(attribute, class: 'control-label')
  end

  def errors
    @errors || object.errors.full_messages_for(attribute)
  end

  def first_error
    @first_error ||= errors.first
  end

  def outer_css
    @outer_css ||= required ? 'form-group required' : 'form-group'
  end

  def object
    @object ||= builder.object
  end

  def invalid?
    @invalid ||= errors.any?
  end

  def valid?
    @valid ||= !invalid? && object.send(attribute)
  end

  def css_class
    @css_class ||= begin
      css_classes = %w[narrow form-control]
      css_classes << 'is-invalid' if invalid?
      css_classes << 'is-valid' if valid?
      css_classes.join(' ')
    end
  end

  def inner_div
    content_tag(:div) do
      concat field_tag
      concat error_feedback_tag if first_error
    end
  end

  def error_feedback_tag
    content_tag(:div, first_error, class: 'invalid-feedback')
  end
end
