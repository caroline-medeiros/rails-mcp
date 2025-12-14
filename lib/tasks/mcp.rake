# frozen_string_literal: true

namespace :mcp do
  desc 'Configura o ambiente e injeta a config no Claude automaticamente'
  task :setup do
    require 'fileutils'
    require 'json'

    wrapper_path = File.expand_path('~/rails-mcp-wrapper.sh')

    script_content = <<~SCRIPT
      #!/bin/zsh
      # Wrapper Rails MCP (Auto-generated v2)
      # Gerado em: #{Time.now}

      # Redireciona logs para debug em caso de erro
      LOGfile="$HOME/mcp-debug.log"
      exec 2>> "$LOGfile"

      PROJECT_PATH=$1

      # 1. Carrega o RVM/Ruby do usuário
      export HOME="#{Dir.home}"
      if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
        source "$HOME/.rvm/scripts/rvm"
      else
        source ~/.zshrc > /dev/null 2>&1
      fi

      # 2. Entra na pasta
      cd "$PROJECT_PATH" || exit 1

      # 3. Detecta versão (Bypass de permissão usando Ruby)
      # O macOS bloqueia 'cat', mas permite o ruby ler o arquivo
      if [ -f ".ruby-version" ]; then
        REQUIRED_VERSION=$(ruby -e 'print File.read(".ruby-version").strip' 2>/dev/null)
        if [ -n "$REQUIRED_VERSION" ]; then
          rvm use "$REQUIRED_VERSION" > /dev/null 2>&1 || true
        else
          rvm use . > /dev/null 2>&1
        fi
      fi

      # 4. Garante dependências
      bundle check > /dev/null 2>&1 || bundle install >&2

      # 5. Roda a gem
      # Tenta rodar pelo binário direto ou via bundle exec
      ./bin/rails-mcp 2>/dev/null || bundle exec rails-mcp
    SCRIPT

    File.write(wrapper_path, script_content)
    FileUtils.chmod(0o755, wrapper_path)
    puts "Script wrapper atualizado em: #{wrapper_path}"

    claude_config_dir = File.expand_path('~/Library/Application Support/Claude')
    claude_config_file = File.join(claude_config_dir, 'claude_desktop_config.json')

    project_name = File.basename(Dir.pwd)
    project_path = Dir.pwd

    FileUtils.mkdir_p(claude_config_dir)

    config = if File.exist?(claude_config_file)
               begin
                 JSON.parse(File.read(claude_config_file))
               rescue JSON::ParserError
                 { 'mcpServers' => {} }
               end
             else
               { 'mcpServers' => {} }
             end

    config['mcpServers'] ||= {}

    config['mcpServers'][project_name] = {
      'command' => wrapper_path,
      'args' => [project_path]
    }

    File.write(claude_config_file, JSON.pretty_generate(config))

    puts ''
    puts 'SUCESSO! Configuração injetada no Claude Desktop.'
    puts "   Projeto: #{project_name}"
    puts "   Arquivo: #{claude_config_file}"
    puts ''
    puts 'Reinicie o Claude Desktop para ver o ícone 🔌.'
  end
end
