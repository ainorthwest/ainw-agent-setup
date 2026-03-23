# frozen_string_literal: true

module Jobs
  class AinwSyncUsernameChange < ::Jobs::Base
    sidekiq_options retry: 3

    def execute(args)
      target_username = args[:target_username]
      field_id = args[:field_id]
      new_value = args[:new_value]

      return if target_username.blank? || field_id.blank? || new_value.blank?

      target_user = User.find_by(username: target_username)
      unless target_user
        Rails.logger.warn("[ainw-agent-setup] Username sync: target user #{target_username} not found")
        return
      end

      target_user.user_fields ||= {}
      target_user.user_fields[field_id.to_s] = new_value
      target_user.save!

      Rails.logger.info("[ainw-agent-setup] Username sync: updated field #{field_id} on #{target_username} to #{new_value}")
    end
  end
end
