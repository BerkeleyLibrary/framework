module ApplicationHelper
  def alerts
    content_tag(:div, class: 'alerts mt-4') do
      flash.each do |lvl, msgs|
        msgs = [msgs] if msgs.kind_of?(String)
        msgs.each do |msg|
          concat content_tag(:div, msg.html_safe, class: "alert alert-#{lvl}")
        end
      end
    end
  end

  def questions_link
    mail_to support_email, 'Questions?', class: 'support-email', tabindex: 5
  end

  def login_link
    if authenticated?
      link_to 'Logout', logout_path, class: "nav-link"
    end
  end

  def logo_link
    link_to(
      image_tag('logo.png', height: '30', alt: "UC Berkeley Library"),
      'http://www.lib.berkeley.edu/',
      { class: "navbar-brand" },
    )
  end

  def page_title
    return content_for :page_title if content_for?(:page_title)

    t_path = "#{controller_path.tr('/', '.')}.#{action_name}.page_title"
    t(t_path, default: :site_name)
  end

  def errors_for(model)
    return unless model.errors.any?

    content_tag(:div, class: "alert alert-warning") do
      concat content_tag(:h5, 'Please correct these errors:')

      content_tag(:ul) do
        model.errors.full_messages.each do |msg|
          concat content_tag(:li, msg).html_safe
        end
      end
    end
  end

  def field_for(builder, attribute, type: :text_field, **kwargs)
    required = kwargs.fetch(:required) { false }

    # Define the label
    label = builder.label(attribute, class: "control-label")

    # Figure out what validation styling to apply
    object = builder.object
    field_errors = object.errors.full_messages_for(attribute)
    css = 'narrow form-control'

    if field_errors.any?
      css += ' is-invalid'
    elsif object.send(attribute)
      css += ' is-valid'
    end

    # Define the field itself
    field = builder.send(type, attribute, { class: css }.update(kwargs))

    # Help text in case of errors
    feedback = content_tag(:div, field_errors.first, class: "invalid-feedback")

    div_css = "form-group"
    div_css += " required" if required
    content_tag(:div, class: div_css) do
      concat label
      concat content_tag(:div, field + feedback)
    end
  end
end
