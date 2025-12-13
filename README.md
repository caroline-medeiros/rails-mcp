# 💎 Rails MCP Server

**Connect your Rails application to AI assistants using the Model Context Protocol (MCP).**

This gem acts as a bridge between your Rails app and AI coding tools (like Cursor, Windsurf, or Claude Desktop). It allows the AI to "read" your application's context directly, preventing hallucinations and improving code generation.

## 🚀 Features

Currently, this MCP Server allows the AI to read:

- **Database Schema:** Reads `db/schema.rb` to understand your tables and columns.
- **Application Routes:** Inspects `Rails.application.routes` to understand your API endpoints and controllers.
- **Active Record (Coming Soon):** Future support for querying data directly.

## 📦 Installation

Add this line to your application's `Gemfile`. Since this is a local/git gem for now, specify the source:

```ruby
# In your Rails App Gemfile
gem 'rails-mcp', git: '[https://github.com/caroline-medeiros/rails-mcp.git](https://github.com/caroline-medeiros/rails-mcp.git)'
```

## And then execute:

``` bundle install ```

## 🔌 Configuration
To use this with an MCP client (like Claude Desktop or Cursor), add the following configuration to your MCP settings file.

For Claude Desktop / Cursor
Add this to your configuration JSON:

```json
{
  "mcpServers": {
    "rails-app": {
      "command": "bundle",
      "args": ["exec", "rails-mcp"]
    }
  }
}
```

Note: You must open your AI editor inside the root folder of your Rails application for the gem to detect the environment correctly.

## 🛠️ Development & Testing

To test the gem locally without installing it in a Rails app, you can use the MCP Inspector:

Clone this repository.

Run the inspector:

```
npx @modelcontextprotocol/inspector ./exe/rails-mcp
```

## 🤝 Contributing
Bug reports and pull requests are welcome on GitHub. This project is intended to be a safe, welcoming space for collaboration.

## 📝 License
The gem is available as open source under the terms of the MIT License.

------------------------------------------------------------------------

## Desenvolvido por

Caroline Medeiros