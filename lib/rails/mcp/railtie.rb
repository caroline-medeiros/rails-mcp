# lib/rails/mcp/railtie.rb
# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'rails/railtie'

module Rails
  module Mcp
    class Railtie < ::Rails::Railtie
      rake_tasks do
        # CORREÇÃO 2: Caminho relativo correto (sobe 2 níveis até lib)
        path = File.expand_path('../../tasks/mcp.rake', __dir__)

        if File.exist?(path)
          load path
        else
          # CORREÇÃO 3: Usa 'warn' para não quebrar o JSON do Claude
          warn "⚠️ [Rails MCP] Task não encontrada em: #{path}"
        end
      end
    end
  end
end
