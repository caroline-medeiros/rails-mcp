💎 Rails MCP Server
===================

**Connect your Rails application to AI assistants using the Model Context Protocol (MCP).**

This gem acts as a bridge between your Rails app and AI coding tools (like Claude Desktop, Cursor, or Windsurf). It allows the AI to "read" your application's context directly, preventing hallucinations and improving code generation.

🚀 Features
-----------

Currently, this MCP Server allows the AI to read:

-   **Database Schema:** Reads `db/schema.rb` to understand your tables and columns.

-   **Application Routes:** Inspects `Rails.application.routes` to understand your API endpoints and controllers.

-   **Active Record (Coming Soon):** Future support for querying data directly.

📦 Installation
---------------

Add this line to your application's `Gemfile`:

Ruby

```
# In your Rails App Gemfile
gem 'rails-mcp', git: 'https://github.com/caroline-medeiros/rails-mcp.git'

```

And then execute:

Bash

```
bundle install

```

🔌 Configuration (The Magic ✨)
------------------------------

Forget about editing JSON files manually! This gem comes with an automated setup task that detects your Ruby environment, creates a secure wrapper script, and configures Claude Desktop for you.

Simply run this command in your project terminal:

Bash

```
bundle exec rake mcp:setup

```

**This task will:**

1.  Generate a `rails-mcp-wrapper.sh` in your home folder (handling RVM/Ruby versions automatically).

2.  Update your `claude_desktop_config.json` adding the current project.

**After running the command:** 👉 **Restart Claude Desktop completely.** You should see the 🔌 icon indicating the tool is connected.

* * * * *

🛠️ Development & Testing
-------------------------

To test the gem locally without installing it in a Rails app, you can use the MCP Inspector:

1.  Clone this repository.

2.  Run the inspector:

Bash

```
npx @modelcontextprotocol/inspector ./exe/rails-mcp

```

🤝 Contributing
---------------

Bug reports and pull requests are welcome on GitHub. This project is intended to be a safe, welcoming space for collaboration.

📝 License
----------

The gem is available as open source under the terms of the MIT License.
----------

by Caroline Medeiros