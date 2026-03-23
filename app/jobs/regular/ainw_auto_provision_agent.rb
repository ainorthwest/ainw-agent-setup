# frozen_string_literal: true

require "net/http"
require "json"

module Jobs
  class AinwAutoProvisionAgent < ::Jobs::Base
    sidekiq_options retry: 3

    def execute(args)
      username = args[:username]
      email = args[:email]

      return if username.blank? || email.blank?

      worker_url = AinwAgentSetup::WORKER_URL
      secret = SiteSetting.ainw_provision_secret

      if secret.blank?
        Rails.logger.warn("[ainw-agent-setup] ainw_provision_secret not configured, skipping auto-provision for #{username}")
        return
      end

      uri = URI("#{worker_url}/api/auto-provision")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30

      request = Net::HTTP::Post.new(uri.path)
      request["Content-Type"] = "application/json"
      request["X-Provision-Secret"] = secret
      request.body = { human_username: username, human_email: email }.to_json

      response = http.request(request)
      body = JSON.parse(response.body) rescue {}

      if response.code.to_i >= 200 && response.code.to_i < 300
        Rails.logger.info("[ainw-agent-setup] Auto-provisioned agent for #{username}: #{body['agent_username']}")
      else
        Rails.logger.error("[ainw-agent-setup] Auto-provision failed for #{username}: #{response.code} #{body['error']}")

        # Notify staff on failure — Sidekiq will retry up to 3 times.
        # The notification fires on every failure so at least one gets through.
        begin
          PostCreator.create!(
            Discourse.system_user,
            title: "Agent auto-provision failed for #{username}",
            raw: "The agent auto-provisioning system failed.\n\n" \
                 "**User:** #{username}\n" \
                 "**Error:** #{body['error'] || 'Unknown'}\n" \
                 "**HTTP Status:** #{response.code}\n\n" \
                 "Please provision this agent manually via the Worker API or Discourse admin.",
            archetype: Archetype.private_message,
            target_usernames: "aaron"
          )
        rescue => e
          Rails.logger.error("[ainw-agent-setup] Failed to send staff notification: #{e.message}")
        end

        raise "Auto-provision failed: #{response.code} #{body['error']}"
      end
    end
  end
end
