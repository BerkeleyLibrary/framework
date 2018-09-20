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

  def login_link
    if authenticated?
      link_to 'Logout', destroy_user_session_path, class: "nav-link"
    else
      link_to 'Login', user_calnet_omniauth_authorize_path, class: "nav-link"
    end
  end

  def logo_link
    link_to(
      image_tag('logo.png', height: '30', alt: "UC Berkeley Library"),
      root_path,
      class: "navbar-brand",
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

  def field_for(builder, field_name, field_type: :text_field, **field_opts)
    content_tag(:div, class: "form-group") do
      concat builder.label(field_name)
      concat builder.text_field(field_name,
        { class: "narrow form-control" }.update(field_opts))
    end
  end
end
