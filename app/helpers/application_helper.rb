module ApplicationHelper
  # rubocop:disable Rails/OutputSafety
  def alerts
    content_tag(:div, class: 'alerts mt-4') do
      flash.each do |lvl, msgs|
        msgs = [msgs] if msgs.is_a?(String)
        msgs.each do |msg|
          concat content_tag(:div, msg.html_safe, class: "alert alert-#{lvl}", role: :status)
        end
      end
    end
  end
  # rubocop:enable Rails/OutputSafety

  def questions_link
    mail_to support_email, 'Questions?', class: 'support-email'
  end

  def login_link
    link_to 'CalNet Logout', logout_path, class: 'nav-link' if authenticated?
  end

  def logo_link
    link_to(
      image_tag('logo.png', height: '30', alt: 'UC Berkeley Library'),
      'http://www.lib.berkeley.edu/',
      { class: 'navbar-brand no-link-style' }
    )
  end

  def page_title
    return content_for :page_title if content_for?(:page_title)

    t_action = action_name == 'show' ? params[:id].to_s : action_name
    t_path = "#{controller_path.tr('/', '.')}.#{t_action}.page_title"
    t(t_path, default: :site_name)
  end

  # rubocop:disable Metrics/ParameterLists

  # Creates a form field with Berkeley Library styling.
  # @param builder [ActionView::Helpers::FormBuilder] enclosing form builder
  # @param attribute [Symbol] attribute name
  # @param type [Symbol] field type
  # @param required [Boolean] true if field is required, false otherwise (default false)
  # @param readonly [Boolean] true if field is read-only, false otherwise (default false)
  # @param html_options [Hash] additional HTML attributes for the input field
  def field_for(builder, attribute, type: :text_field, required: false, readonly: false, html_options: {})
    field_builder = FieldBuilder.new(
      tag_helper: self,
      builder:,
      attribute:,
      type:,
      required:,
      readonly:,
      html_options:
    )
    field_builder.build
  end
  # rubocop:enable Metrics/ParameterLists

  def sortable(column, title = nil, param = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction} no-link-style" : 'no-link-style'
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'
    link_to title, { sort: column, direction:, param: }, { class: css_class }
  end
end
