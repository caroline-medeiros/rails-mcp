# frozen_string_literal: true

namespace :mcp do
  desc 'Configura o ambiente e injeta a config no Claude automaticamente'
  task :setup do
    require 'fileutils'
    require 'json'

    wrapper_path = File.expand_path('~/rails-mcp-wrapper.sh')

    script_content = <<~SCRIPT
      #!/bin/bash
      # Wrapper Rails MCP (Silent Mode)
      # Gerado em: #{Time.now}

      # 1. Redireciona TUDO que não for explicito para o log
      # Isso impede que erros do shell ou do tema sujem o canal JSON
      LOGfile="$HOME/mcp-debug.log"
      exec 2>> "$LOGfile"

      PROJECT_PATH=$1

      # 2. Carrega RVM ou rbenv de forma minimalista (sem carregar temas do ZSH)
      export HOME="#{Dir.home}"

      # Tenta carregar o perfil bash (mais limpo que zshrc) ou carrega RVM direto
      if [ -s "$HOME/.rvm/scripts/rvm" ]; then
        source "$HOME/.rvm/scripts/rvm" > /dev/null 2>&1
      elif [ -d "$HOME/.rbenv/bin" ]; then
        export PATH="$HOME/.rbenv/bin:$PATH"
        eval "$(rbenv init - bash)" > /dev/null 2>&1
      fi

      # 3. Entra na pasta
      cd "$PROJECT_PATH" || exit 1

      # 4. Força a versão do Ruby (Bypass de permissão)
      if [ -f ".ruby-version" ]; then
        # Lê a versão usando Ruby para evitar erro de permissão do 'cat'
        REQUIRED_VERSION=$(ruby -e 'print File.read(".ruby-version").strip' 2>/dev/null)
      #{'  '}
        if [ -n "$REQUIRED_VERSION" ]; then
          # Tenta mudar a versão silenciosamente
          rvm use "$REQUIRED_VERSION" > /dev/null 2>&1 || true
          rbenv local "$REQUIRED_VERSION" > /dev/null 2>&1 || true
        fi
      fi

      # 5. Roda a gem garantindo que STDIN/STDOUT estão limpos
      # O 'exec' substitui o processo do shell pelo do Ruby
      bundle check > /dev/null 2>&1 || bundle install > /dev/null 2>&1

      exec bundle exec rails-mcp
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

    puts "SUCESSO! Configuração injetada no Claude Desktop para: #{project_name}"
    puts 'Reinicie o Claude Desktop para aplicar.'
  end
end
