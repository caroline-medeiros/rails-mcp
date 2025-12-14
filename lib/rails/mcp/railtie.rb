# lib/rails/mcp/railtie.rb
# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'rails/railtie'

module Rails
  module Mcp
    class Railtie < ::Rails::Railtie
      rake_tasks do
        path = File.expand_path('../../tasks/mcp.rake', __dir__)

        if File.exist?(path)
          load path
        else
          warn "[Rails MCP] Task não encontrada em: #{path}"
        end
      end
    end
  end
end
