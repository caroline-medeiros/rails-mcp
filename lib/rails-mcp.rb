# lib/rails-mcp.rb
# frozen_string_literal: true

require 'rails/mcp/version'
require 'rails/mcp/server'

require 'rails/mcp/railtie'

module Rails
  module Mcp
    class Error < StandardError; end
  end
end
