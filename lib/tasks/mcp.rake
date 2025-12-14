# frozen_string_literal: true

namespace :mcp do
  desc 'Configura o ambiente e injeta a config no Claude automaticamente'
  task :setup do
    require 'fileutils'
    require 'json'

    wrapper_path = File.expand_path('~/rails-mcp-wrapper.sh')

    script_content = <<~SCRIPT
      #!/bin/bash
      # Wrapper Rails MCP (Nuclear Option)
      # Gerado em: #{Time.now}

      # 1. Redireciona logs para debug (crucial para não sujar o JSON)
      LOGfile="$HOME/mcp-debug.log"
      exec 2>> "$LOGfile"

      PROJECT_PATH="$1"
      
      # Garante que o HOME está setado
      export HOME="#{Dir.home}"
      
      # Entra no projeto
      cd "$PROJECT_PATH" || { echo "Erro ao entrar em $PROJECT_PATH" >&2; exit 1; }

      # --- TRUQUE PARA LER VERSÃO SEM PERMISSÃO DE LEITURA DIRETA ---
      # O macOS bloqueia 'cat .ruby-version', mas o binário do ruby geralmente consegue ler.
      # Tentamos ler a versão usando o ruby padrão do sistema ou qualquer um disponível.
      
      RUBY_VERSION_FILE=".ruby-version"
      REQUIRED_VERSION=""

      if [ -f "$RUBY_VERSION_FILE" ]; then
        # Tenta ler usando ruby
        REQUIRED_VERSION=$(ruby -e "puts File.read('$RUBY_VERSION_FILE').strip" 2>/dev/null)
        
        # Se falhou (ruby não achou), tenta head/cat (vai que...)
        if [ -z "$REQUIRED_VERSION" ]; then
           REQUIRED_VERSION=$(head -n 1 "$RUBY_VERSION_FILE" 2>/dev/null)
        fi
      fi

      echo "--> Projeto: $PROJECT_PATH" >&2
      echo "--> Versão detectada: ${REQUIRED_VERSION:-Indefinida}" >&2

      # --- CARREGA O RVM ---
      # Carregamos o RVM explicitamente para ter acesso ao comando 'rvm'
      if [ -s "$HOME/.rvm/scripts/rvm" ]; then
        source "$HOME/.rvm/scripts/rvm"
        
        # Se descobrimos a versão, forçamos o uso dela
        if [ -n "$REQUIRED_VERSION" ]; then
          echo "--> Forçando RVM use $REQUIRED_VERSION" >&2
          rvm use "$REQUIRED_VERSION" > /dev/null 2>&1
        else
          # Se não, tenta o padrão
          rvm use . > /dev/null 2>&1
        fi
      elif [ -d "$HOME/.rbenv/bin" ]; then
         export PATH="$HOME/.rbenv/bin:$PATH"
         eval "$(rbenv init - bash)" > /dev/null 2>&1
         if [ -n "$REQUIRED_VERSION" ]; then
            rbenv local "$REQUIRED_VERSION" > /dev/null 2>&1
         fi
      fi

      # --- EXECUÇÃO ---
      # Garante dependências silenciosamente
      bundle check > /dev/null 2>&1 || bundle install > /dev/null 2>&1

      # Roda a gem usando 'exec' para substituir o processo shell
      # Isso garante que os sinais (como fechar conexão) vão direto pro Ruby
      echo "--> Iniciando Rails MCP..." >&2
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
