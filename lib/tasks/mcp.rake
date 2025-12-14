# frozen_string_literal: true

# lib/tasks/mcp.rake

namespace :mcp do
  desc 'Setup Rails MCP wrapper for Claude Desktop'
  task :setup do
    require 'fileutils'

    wrapper_path = File.join(Dir.home, 'rails-mcp-wrapper.sh')

    wrapper_content = <<~'SCRIPT'
      #!/bin/bash
      # Wrapper Rails MCP - Universal (RVM, rbenv, asdf, mise)
      # Gerado via rake mcp:setup

      # 1. Configuração de Logs e Ambiente
      LOGfile="$HOME/mcp-debug.log"
      exec 2>> "$LOGfile"

      PROJECT_PATH="$1"
      export HOME=$(echo ~) # Garante o HOME correto

      # Garante UTF-8 para evitar erros de encoding no Ruby
      export LANG="en_US.UTF-8"
      export LC_ALL="en_US.UTF-8"

      echo "----------------------------------------" >&2
      echo "Iniciando Wrapper Universal em: $(date)" >&2
      echo "Projeto: $PROJECT_PATH" >&2

      # Entra na pasta do projeto
      cd "$PROJECT_PATH" || { echo "FATAL: Falha ao acessar $PROJECT_PATH" >&2; exit 1; }

      # ==============================================================================
      # SEÇÃO DE DETECÇÃO DE GERENCIADORES DE VERSÃO
      # ==============================================================================

      MANAGER_FOUND="não"

      # --- TENTATIVA 1: MISE (O sucessor moderno do asdf/rtx) ---
      if [ -f "$HOME/.local/bin/mise" ] || command -v mise >/dev/null 2>&1; then
        echo "Tentando carregar mise..." >&2
        export PATH="$HOME/.local/bin:$PATH"
        eval "$(mise activate bash)"
        MANAGER_FOUND="mise"
      fi

      # --- TENTATIVA 2: ASDF ---
      # Verifica instalação padrão e Homebrew
      if [ "$MANAGER_FOUND" = "não" ]; then
        if [ -f "$HOME/.asdf/asdf.sh" ]; then
          echo "Tentando carregar asdf (Home)..." >&2
          . "$HOME/.asdf/asdf.sh"
          MANAGER_FOUND="asdf"
        elif [ -f "/opt/homebrew/opt/asdf/libexec/asdf.sh" ]; then
          echo "Tentando carregar asdf (Brew)..." >&2
          . "/opt/homebrew/opt/asdf/libexec/asdf.sh"
          MANAGER_FOUND="asdf"
        fi
      fi

      # --- TENTATIVA 3: RBENV ---
      if [ "$MANAGER_FOUND" = "não" ]; then
        # Checa se o diretório existe ou se o comando está no path
        if [ -d "$HOME/.rbenv" ] || command -v rbenv >/dev/null 2>&1; then
          echo "Tentando carregar rbenv..." >&2
          export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
          if command -v rbenv > /dev/null; then
            eval "$(rbenv init - bash)"
            MANAGER_FOUND="rbenv"
          fi
        fi
      fi

      # --- TENTATIVA 4: RVM ---
      if [ "$MANAGER_FOUND" = "não" ]; then
        if [ -s "$HOME/.rvm/scripts/rvm" ]; then
          echo "Tentando carregar RVM..." >&2
          source "$HOME/.rvm/scripts/rvm"
          # Força o carregamento da versão definida no arquivo .ruby-version ou .rvmrc
          rvm use . > /dev/null 2>&1
          MANAGER_FOUND="rvm"
        fi
      fi

      # ==============================================================================
      # VERIFICAÇÃO FINAL
      # ==============================================================================

      RUBY_LOC=$(which ruby)
      echo "Gerenciador detectado: $MANAGER_FOUND" >&2
      echo "Ruby atual: $RUBY_LOC" >&2

      # Segurança: Bloqueia se estiver rodando com o Ruby do macOS
      if [[ "$RUBY_LOC" == *"/System/Library"* ]] || [[ "$RUBY_LOC" == *"/usr/bin/ruby"* ]]; then
        echo "ERRO CRÍTICO: Nenhum gerenciador (rbenv/asdf/rvm) assumiu o controle." >&2
        echo "Estou rodando com o Ruby do sistema e isso vai falhar." >&2
        echo "Verifique se o seu gerenciador está instalado no \$HOME padrão." >&2
        exit 1
      fi

      # ==============================================================================
      # EXECUÇÃO DO SERVIDOR
      # ==============================================================================

      # Garante dependências sem travar a thread
      bundle check > /dev/null 2>&1 || bundle install > /dev/null 2>&1

      echo "Iniciando rails-mcp..." >&2
      exec bundle exec rails-mcp
    SCRIPT

    # Escreve o arquivo
    File.write(wrapper_path, wrapper_content)

    # Torna executável
    FileUtils.chmod('+x', wrapper_path)

    puts "Script wrapper atualizado em: #{wrapper_path}"
    puts "SUCESSO! Configuração injetada no Claude Desktop para: #{File.basename(Dir.pwd)}"
    puts 'Reinicie o Claude Desktop para aplicar.'
  end
end
