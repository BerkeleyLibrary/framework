require 'json'

module Alma
  class User
    include ActiveModel::Model

    # Won't be needed.. temp for working out model specs that depend on these values....
    # Any two-digit year over this, and Ruby's Date.parse() will wrap back to 1969.
    MILLENNIUM_MAX_DATE = Date.new(2068, 12, 31)

    # Any two-digit year below this, and Ruby's Date.parse() will wrap ahead to 2068.
    MILLENNIUM_MIN_DATE = Date.new(1969, 1, 1)

    attr_accessor :user_obj
    attr_accessor :id
    attr_accessor :email
    attr_accessor :blocks
    attr_accessor :name
    attr_accessor :type
    attr_accessor :expiration_date

    class << self
      def find(id)
        raw_user = AlmaServices::Patron.get_user(id)

        # If we get no user back return nothing
        return unless raw_user

        # If Alma sends back and error return nothing
        return if raw_user.body['errorsExist']

        Alma::User.new raw_user
      end

      def find_if_exists(id)
        return unless id

        find(id)
      end

      def find_if_active(id)
        find_if_exists(id).tap do |rec|
          return nil unless rec && rec.active?
        end
      end
    end

    # rubocop:disable Metrics/AbcSize
    def initialize(raw_user = nil)
      return unless raw_user

      @user_obj = JSON.parse raw_user.body
      @id = @user_obj['primary_id']
      @name = @user_obj['full_name']
      @email = @user_obj['contact_info']['email'][0]['email_address']

      # Alma codes have a history of being mixed case so upcase user_group:
      @type = @user_obj['user_group']['value'].upcase if @user_obj['user_group']['value']
      @expiration_date = Date.strptime(@user_obj['expiry_date'], '%Y-%m-%d') if @user_obj['expiry_date']
    end
    # rubocop:enable Metrics/AbcSize

    def to_json(*_args)
      user_obj.to_json
    end

    def save
      AlmaServices::Patron.save(@id, self)
    end

    def active?
      !expired?
    end

    def expired?
      return true unless expiration_date

      expiration_date < Date.current
    end

    def fees
      AlmaServices::Fees.fetch_all(@id) || nil
    end

    # TODO: Clean up use of notes_array vs. find_note
    def notes_array
      user_obj['user_note'].map { |n| n['note_text'] }
    end

    # TODO: Clean up use of notes_array vs. find_note
    def find_note(note)
      @user_obj['user_note'].find { |p| p['note_text'].include? note }
    end

    def delete_note(note)
      @user_obj['user_note'].reject! { |p| p['note_text'].include? note }
    end

    # Types: Library, Address, Barcode, Circulation, ERP, General, Other, Registrar
    # rubocop:disable Metrics/MethodLength
    def add_note(text)
      Rails.logger.debug("Setting note #{text} for patron #{id}")

      new_note = {
        'note_type' => { 'value' => 'LIBRARY', 'desc' => 'Library' },
        'note_text' => text,
        'user_viewable' => false,
        'popup_note' => false,
        'created_by' => 'Framework',
        'created_date' => Time.zone.now.strftime('%Y-%m-%dT%H:%M:00Z'),
        'segment_type' => 'Internal'
      }
      user_obj['user_note'].push(new_note)
    end
    # rubocop:enable Metrics/MethodLength
  end
end
