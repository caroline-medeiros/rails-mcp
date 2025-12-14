# frozen_string_literal: true

# lib/tasks/mcp.rake
namespace :mcp do
  desc 'Configura o ambiente para uso com Claude Desktop'
  task :setup do
    require 'fileutils'

    wrapper_path = File.expand_path('~/rails-mcp-wrapper.sh')
    script_content = <<~SCRIPT
      #!/bin/zsh
      # Gerado automaticamente por rails-mcp v1.0

      PROJECT_PATH=$1

      if [ -z "$PROJECT_PATH" ]; then
        echo "Erro: Caminho do projeto não fornecido." >&2
        exit 1
      fi

      # 1. Carrega o RVM/Asdf do usuário
      export HOME="#{Dir.home}"
      if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
        source "$HOME/.rvm/scripts/rvm"
      elif [[ -f "$HOME/.asdf/asdf.sh" ]]; then
        source "$HOME/.asdf/asdf.sh"
      else
        source ~/.zshrc > /dev/null 2>&1
      fi

      # 2. Entra na pasta do projeto
      cd "$PROJECT_PATH" || { echo "Pasta não encontrada" >&2; exit 1; }

      # 3. DETECTA VERSÃO DO RUBY (.ruby-version)
      # Isso resolve o problema de conflito (ex: 3.4.6 vs 3.4.7)
      if [ -f ".ruby-version" ]; then
        REQUIRED_VERSION=$(cat .ruby-version | tr -d '[:space:]')
        # Tenta trocar para a versão que o projeto pede
        rvm use "$REQUIRED_VERSION" > /dev/null 2>&1 || true
      fi

      # 4. Roda a gem
      bundle exec rails-mcp
    SCRIPT

    File.write(wrapper_path, script_content)
    File.chmod(0o755, wrapper_path)

    puts "✅ Script de ponte criado/atualizado com sucesso em: #{wrapper_path}"
    puts ''
    puts '📋 COPIE O JSON ABAIXO PARA O SEU CLAUDE CONFIG:'
    puts '   (Arquivo: ~/Library/Application Support/Claude/claude_desktop_config.json)'
    puts ''
    puts '{'
    puts '  "mcpServers": {'
    puts "    \"#{File.basename(Dir.pwd)}\": {"
    puts "      \"command\": \"#{wrapper_path}\","
    puts "      \"args\": [\"#{Dir.pwd}\"]"
    puts '    }'
    puts '  }'
    puts '}'
    puts ''
  end
end
