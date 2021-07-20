class LendingItemPresenterBase
  attr_reader :view_context, :item

  delegate_missing_to :@view_context

  def initialize(view_context, item, show_viewer:, show_copyright_warning: false)
    @view_context = view_context
    @item = item
    @show_viewer = show_viewer
    @show_copyright_warning = show_copyright_warning
  end

  def show_viewer?
    @show_viewer
  end

  def show_copyright_warning?
    @show_copyright_warning
  end

  def fields
    @fields ||= marc_metadata.to_display_fields.tap do |fields|
      fields.merge!(additional_fields) if respond_to?(:additional_fields)
    end
  end

  def directory
    item.directory
  end

  def viewer_title
    'View'
  end

  def title
    marc_metadata.title
  end

  def to_yes_or_no(b)
    b ? 'Yes' : 'No'
  end

  private

  def marc_metadata
    item.marc_metadata
  end
end
