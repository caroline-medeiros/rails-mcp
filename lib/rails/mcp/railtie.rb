# frozen_string_literal: true

module Rails
  module Mcp
    class Railtie < ::Rails::Railtie
      rake_tasks do
        load 'tasks/mcp.rake'
      end
    end
  end
end
