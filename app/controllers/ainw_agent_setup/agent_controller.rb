# frozen_string_literal: true

module AinwAgentSetup
  class AgentController < ::ApplicationController
    requires_login

    def index
      render_json_dump({})
    end
  end
end
