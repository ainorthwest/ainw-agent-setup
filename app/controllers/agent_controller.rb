# frozen_string_literal: true

module AinwAgentSetup
  class AgentController < ::ApplicationController
    requires_login

    def index
      render json: {
        current_user: {
          username: current_user.username,
          groups: current_user.groups.pluck(:name),
        },
      }
    end
  end
end
