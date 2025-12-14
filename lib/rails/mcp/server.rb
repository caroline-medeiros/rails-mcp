# frozen_string_literal: true

require 'json'

module Rails
  module Mcp
    class Server
      def start
        $stdin.each_line do |line|
          handle_message(line)
        rescue StandardError => e
          warn "Erro ao processar mensagem: #{e.message}"
          warn e.backtrace.join("\n")
        end
      end

      private

      def handle_message(line)
        request = JSON.parse(line)

        # Roteador de mensagens
        response = case request['method']
                   when 'initialize'
                     handle_initialize(request)
                   when 'notifications/initialized'
                     nil
                   when 'resources/list'
                     handle_list_resources(request)
                   when 'resources/read'
                     handle_read_resource(request)
                   when 'tools/list'
                     handle_list_tools(request)
                   when 'tools/call'
                     handle_call_tool(request)
                   end

        return unless response

        $stdout.print "#{response.to_json}\n"
        $stdout.flush
      end

      def handle_initialize(request)
        {
          jsonrpc: '2.0',
          id: request['id'],
          result: {
            protocolVersion: '2024-11-05',
            capabilities: {
              resources: {},
              tools: {}
            },
            serverInfo: { name: 'rails-mcp', version: Rails::Mcp::VERSION }
          }
        }
      end

      def handle_list_resources(request)
        {
          jsonrpc: '2.0',
          id: request['id'],
          result: {
            resources: [
              { uri: 'rails://schema', name: 'Schema do Banco', mimeType: 'application/ruby' },
              { uri: 'rails://routes', name: 'Rotas da Aplicação', mimeType: 'text/plain' }
            ]
          }
        }
      end

      def handle_read_resource(request)
        uri = request.dig('params', 'uri')
        content = case uri
                  when 'rails://schema'
                    File.exist?('db/schema.rb') ? File.read('db/schema.rb') : 'Schema não encontrado.'
                  when 'rails://routes'
                    `bundle exec rails routes`
                  else
                    'Recurso desconhecido'
                  end

        {
          jsonrpc: '2.0',
          id: request['id'],
          result: {
            contents: [{ uri: uri, mimeType: 'text/plain', text: content }]
          }
        }
      end

      def handle_list_tools(request)
        {
          jsonrpc: '2.0',
          id: request['id'],
          result: {
            tools: [
              {
                name: 'ls',
                description: 'Lista arquivos e pastas dentro do projeto Rails.',
                inputSchema: {
                  type: 'object',
                  properties: {
                    path: { type: 'string', description: 'Caminho relativo (ex: app/models)' }
                  },
                  required: ['path']
                }
              },
              {
                name: 'read_file',
                description: 'Lê o conteúdo de um arquivo de código.',
                inputSchema: {
                  type: 'object',
                  properties: {
                    path: { type: 'string', description: 'Caminho do arquivo (ex: app/models/user.rb)' }
                  },
                  required: ['path']
                }
              }
            ]
          }
        }
      end

      def handle_call_tool(request)
        name = request.dig('params', 'name')
        args = request.dig('params', 'arguments')

        result_content = case name
                         when 'ls'
                           list_files(args['path'])
                         when 'read_file'
                           read_file_content(args['path'])
                         else
                           'Ferramenta desconhecida'
                         end

        {
          jsonrpc: '2.0',
          id: request['id'],
          result: {
            content: [{ type: 'text', text: result_content }]
          }
        }
      end

      def list_files(path)
        return 'Erro: Caminho inválido (tentativa de sair do root)' if path.include?('..')

        full_path = File.join(Dir.pwd, path)

        if File.directory?(full_path)
          entries = Dir.entries(full_path) - ['.', '..']
          entries.map { |e| File.directory?(File.join(full_path, e)) ? "#{e}/" : e }.join("\n")
        else
          "Erro: Diretório não encontrado: #{path}"
        end
      rescue StandardError => e
        "Erro ao listar arquivos: #{e.message}"
      end

      def read_file_content(path)
        return 'Erro: Caminho inválido (tentativa de sair do root)' if path.include?('..')

        full_path = File.join(Dir.pwd, path)

        if File.file?(full_path)
          File.read(full_path)
        else
          "Erro: Arquivo não encontrado: #{path}"
        end
      rescue StandardError => e
        "Erro ao ler arquivo: #{e.message}"
      end
    end
  end
end
