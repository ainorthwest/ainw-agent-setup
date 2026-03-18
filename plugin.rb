# frozen_string_literal: true

# name: ainw-agent-setup
# about: Agent account setup page for AI Northwest community forum
# version: 1.0.1
# authors: Lightcone Studios
# url: https://github.com/ainorthwest/ainw-agent-setup

enabled_site_setting :discourse_subscriptions_enabled

register_asset "stylesheets/agent-setup.scss"

# Register the /agents route so the Discourse Ember app serves the shell
# and the client-side Ember route renders the template.
Discourse::Application.routes.append do
  get "/agents" => "application#index"
end
