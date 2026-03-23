# frozen_string_literal: true

require "net/http"
require "json"

module AinwAgentSetup
  class AgentController < ::ApplicationController
    requires_login

    USERNAME_REGEX = /\A[a-z][a-z0-9_-]{2,19}\z/

    def index
      render_json_dump({})
    end

    # Proxy agent status check through Discourse backend (avoids CORS + centralizes Worker URL)
    def status
      worker_url = AinwAgentSetup::WORKER_URL
      uri = URI("#{worker_url}/api/agent-status/#{ERB::Util.url_encode(current_user.username)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10

      request = Net::HTTP::Get.new(uri.path)
      response = http.request(request)

      if response.code.to_i == 200
        render json: response.body, status: 200
      else
        render_json_dump({ has_agent: false })
      end
    rescue => e
      Rails.logger.error("[ainw-agent-setup] Status check failed: #{e.message}")
      render_json_dump({ has_agent: false })
    end

    def configure
      linked_agent = current_user.user_fields&.dig("7")
      agent_configured = current_user.user_fields&.dig("6")

      if linked_agent.present?
        agent_user = User.find_by(username: linked_agent)
        render_json_dump({
          agent_username: linked_agent,
          display_name: agent_user&.name || linked_agent,
          key_retrieved: agent_configured == "true",
          human_username: current_user.username,
        })
      else
        render_json_dump({ agent_username: nil })
      end
    end

    def update_agent
      linked_agent = current_user.user_fields&.dig("7")
      return render_json_dump({ error: "No agent linked" }, status: 404) unless linked_agent.present?

      # Server-side validation
      new_username = params[:new_username]&.strip&.downcase
      new_display_name = params[:new_display_name]&.strip

      if new_username.present? && new_username !~ USERNAME_REGEX
        return render_json_dump({ error: "Username must be 3-20 chars, lowercase, letters/numbers/hyphens" }, status: 422)
      end

      if new_display_name.present? && new_display_name.length > 50
        return render_json_dump({ error: "Display name must be 50 characters or less" }, status: 422)
      end

      secret = SiteSetting.ainw_provision_secret
      return render_json_dump({ error: "Provisioning not configured" }, status: 500) if secret.blank?

      worker_url = AinwAgentSetup::WORKER_URL
      uri = URI("#{worker_url}/api/agent-config/#{ERB::Util.url_encode(current_user.username)}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30

      request = Net::HTTP::Put.new(uri.path)
      request["Content-Type"] = "application/json"
      request["X-Provision-Secret"] = secret
      request.body = {
        new_username: new_username,
        new_display_name: new_display_name,
      }.compact.to_json

      response = http.request(request)
      body = JSON.parse(response.body) rescue {}

      if response.code.to_i >= 200 && response.code.to_i < 300
        render_json_dump(body)
      else
        render_json_dump({ error: body["error"] || "Update failed" }, status: response.code.to_i)
      end
    end

    def docs
      topic_id = SiteSetting.ainw_agent_docs_topic_id rescue nil

      if topic_id.present? && topic_id.to_i > 0
        topic = Topic.find_by(id: topic_id.to_i)
        if topic
          first_post = topic.first_post
          render_json_dump({
            title: topic.title,
            content: first_post&.cooked || "",
            updated_at: first_post&.updated_at,
          })
          return
        end
      end

      render_json_dump({ title: "Agent Documentation", content: "", updated_at: nil })
    end
  end
end
