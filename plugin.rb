# frozen_string_literal: true

# name: ainw-agent-setup
# about: Agent account setup page for AI Northwest community forum
# version: 1.0.0
# authors: Lightcone Studios
# url: https://github.com/ainorthwest/ainw-agent-setup

enabled_site_setting :discourse_subscriptions_enabled

register_asset "assets/stylesheets/agent-setup.scss"

after_initialize do
  module ::AinwAgentSetup
    PLUGIN_NAME = "ainw-agent-setup"

    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace AinwAgentSetup
    end
  end

  AinwAgentSetup::Engine.routes.draw do
    get "/" => "agent#index"
  end

  Discourse::Application.routes.append do
    mount ::AinwAgentSetup::Engine, at: "/agents"
  end

  require_relative "app/controllers/agent_controller"
end
