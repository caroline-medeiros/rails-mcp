# frozen_string_literal: true

# lib/tasks/mcp.rake
require 'json'
require 'fileutils'

namespace :mcp do
  desc 'Setup Rails MCP wrapper and inject config into Claude Desktop'
  task :setup do
    wrapper_path = File.join(Dir.home, 'rails-mcp-wrapper.sh')
    claude_config_path = File.expand_path('~/Library/Application Support/Claude/claude_desktop_config.json')

    current_app_name = File.basename(Dir.pwd)
    current_app_path = Dir.pwd

    wrapper_content = <<~'SCRIPT'
      #!/bin/bash
      # Wrapper Rails MCP - Versão Final (Smart ASDF + Logs + Spring Killer)
      # Gerado via rake mcp:setup

      LOGfile="$HOME/mcp-debug.log"
      exec 2>> "$LOGfile"

      PROJECT_PATH="$1"
      export HOME=$(echo ~)
      export LANG="en_US.UTF-8"
      export LC_ALL="en_US.UTF-8"

      # --- BLOQUEIO DE RUÍDOS (CRUCIAL PARA O CLAUDE) ---
      export DISABLE_SPRING=1              # Mata o Spring (maior causador de ruído)
      export RAILS_LOG_TO_STDOUT=false     # Impede logs do Rails no terminal
      export BUNDLE_SILENCE_ROOT_WARNING=1 # Evita avisos do Bundler
      # --------------------------------------------------

      cd "$PROJECT_PATH" || { echo "FATAL: Falha ao acessar $PROJECT_PATH" >&2; exit 1; }

      MANAGER_FOUND="não"

      # --- TENTATIVA 1: MISE ---
      if [ -f "$HOME/.local/bin/mise" ] || command -v mise >/dev/null 2>&1; then
        export PATH="$HOME/.local/bin:$PATH"
        eval "$(mise activate bash)"
        MANAGER_FOUND="mise"
      fi

      # --- TENTATIVA 2: ASDF (Com Smart Fix para .ruby-version) ---
      if [ "$MANAGER_FOUND" = "não" ]; then
        if [ -f "$HOME/.asdf/asdf.sh" ]; then . "$HOME/.asdf/asdf.sh"; MANAGER_FOUND="asdf"; fi
        if [ -f "/opt/homebrew/opt/asdf/libexec/asdf.sh" ]; then . "/opt/homebrew/opt/asdf/libexec/asdf.sh"; MANAGER_FOUND="asdf"; fi

        # Se achou asdf mas não tem .tool-versions e tem .ruby-version
        if [ "$MANAGER_FOUND" = "asdf" ] && [ ! -f ".tool-versions" ] && [ -f ".ruby-version" ]; then
          # Lê a versão, remove espaços e o prefixo 'ruby-' se existir
          RUBY_VER=$(cat .ruby-version | tr -d '\n' | tr -d ' ' | sed 's/ruby-//')
          export ASDF_RUBY_VERSION=$RUBY_VER
        fi
      fi

      # --- TENTATIVA 3: RBENV ---
      if [ "$MANAGER_FOUND" = "não" ]; then
        if [ -d "$HOME/.rbenv" ]; then
          export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
          if command -v rbenv > /dev/null; then eval "$(rbenv init - bash)"; MANAGER_FOUND="rbenv"; fi
        fi
      fi

      # --- TENTATIVA 4: RVM ---
      if [ "$MANAGER_FOUND" = "não" ]; then
        if [ -s "$HOME/.rvm/scripts/rvm" ]; then source "$HOME/.rvm/scripts/rvm"; rvm use . > /dev/null; MANAGER_FOUND="rvm"; fi
      fi

      # EXECUÇÃO DO SERVIDOR
      # 1. Garante dependências
      bundle check > /dev/null 2>&1 || bundle install > /dev/null 2>&1

      # 2. Tenta rodar via binstub (mais rápido/seguro) ou bundle exec (padrão)
      if [ -f "bin/rails-mcp" ]; then
        exec bin/rails-mcp
      else
        exec bundle exec rails-mcp
      fi
    SCRIPT

    File.write(wrapper_path, wrapper_content)
    FileUtils.chmod('+x', wrapper_path)
    puts "✅ Script wrapper atualizado em: #{wrapper_path}"

    FileUtils.mkdir_p(File.dirname(claude_config_path))

    if File.exist?(claude_config_path)
      begin
        config_data = JSON.parse(File.read(claude_config_path))
      rescue JSON::ParserError
        config_data = {}
      end
    else
      config_data = {}
    end

    config_data['mcpServers'] ||= {}

    config_data['mcpServers'][current_app_name] = {
      'command' => wrapper_path,
      'args' => [current_app_path]
    }

    File.write(claude_config_path, JSON.pretty_generate(config_data))

    puts "Configuração do Claude atualizada para: #{current_app_name}"
    puts "Caminho: #{current_app_path}"
    puts 'Reinicie o Claude Desktop para aplicar as mudanças.'
  end
end
