# frozen_string_literal: true

# name: ainw-agent-setup
# about: Agent account setup, auto-provisioning, and management for AI Northwest community forum
# version: 2.0.0
# authors: Lightcone Studios
# url: https://github.com/ainorthwest/ainw-agent-setup

register_asset "stylesheets/agent-setup.scss"

after_initialize do
  module ::AinwAgentSetup
    PLUGIN_NAME = "ainw-agent-setup"
    WORKER_URL = "https://ainw-agent-provisioner.lightcone.workers.dev"

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace AinwAgentSetup
    end
  end

  # Load jobs before event hooks that reference them
  require_relative "app/jobs/regular/ainw_auto_provision_agent"
  require_relative "app/jobs/regular/ainw_sync_username_change"
  require_relative "app/controllers/ainw_agent_setup/agent_controller"

  # Routes
  AinwAgentSetup::Engine.routes.draw do
    get "/" => "agent#index"
    get ".json" => "agent#index"
    get "/status" => "agent#status"
    get "/status.json" => "agent#status"
    get "/configure" => "agent#configure"
    get "/configure.json" => "agent#configure"
    put "/configure" => "agent#update_agent"
    get "/docs" => "agent#docs"
    get "/docs.json" => "agent#docs"
  end

  Discourse::Application.routes.append do
    mount ::AinwAgentSetup::Engine, at: "/agents"
  end

  # Auto-provision agent when user is added to the "bundle" group
  # Guarded narrowly — only the provisioning hook needs Subscriptions to be active
  DiscourseEvent.on(:user_added_to_group) do |user, group|
    next unless group.name == "bundle"

    # Skip if user already has a linked agent (field 7) — string keys
    linked_agent = user.user_fields&.dig("7")
    next if linked_agent.present?

    Jobs.enqueue(
      :ainw_auto_provision_agent,
      user_id: user.id,
      username: user.username,
      email: user.email
    )
  end

  # Username change sync — bidirectional
  DiscourseEvent.on(:user_updated) do |user|
    if user.saved_change_to_username?
      new_username = user.username

      linked_agent = user.user_fields&.dig("7")
      linked_human = user.user_fields&.dig("8")

      if linked_agent.present?
        Jobs.enqueue(
          :ainw_sync_username_change,
          target_username: linked_agent,
          field_id: "8",
          new_value: new_username
        )
      elsif linked_human.present?
        Jobs.enqueue(
          :ainw_sync_username_change,
          target_username: linked_human,
          field_id: "7",
          new_value: new_username
        )
      end
    end
  end
end
