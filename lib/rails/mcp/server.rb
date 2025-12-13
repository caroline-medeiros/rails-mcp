# frozen_string_literal: true

require 'json'

module Rails
  module Mcp
    class Server
      def start
        warn 'Rails MCP Server iniciado...'
        $stdin.each_line do |line|
          handle_message(line)
        rescue StandardError => e
          warn "ERRO FATAL: #{e.message}"
          warn e.backtrace.join("\n")
        end
      end

      private

      def handle_message(line)
        return if line.strip.empty?

        request = JSON.parse(line)
        warn "Recebi método: #{request['method']}"

        case request['method']
        when 'initialize'
          response = {
            jsonrpc: '2.0',
            id: request['id'],
            result: {
              protocolVersion: '2024-11-05',
              capabilities: {
                resources: {}
              },
              serverInfo: {
                name: 'rails-mcp',
                version: '0.1.0'
              }
            }
          }
          send_response(response)

        when 'notifications/initialized'
          warn 'Conexão estabelecida!'

        when 'resources/list'
          response = {
            jsonrpc: '2.0',
            id: request['id'],
            result: {
              resources: [
                {
                  uri: 'rails://schema',
                  name: 'Schema do Banco',
                  mimeType: 'application/ruby'
                },
                {
                  uri: 'rails://routes',
                  name: 'Rotas da Aplicação',
                  mimeType: 'text/plain'
                }
              ]
            }
          }
          send_response(response)

        when 'resources/read'
          full_uri = request.dig('params', 'uri')

          uri, query_string = full_uri.split('?')
          search_term = query_string&.split('q=')&.last

          content = ''

          if uri == 'rails://schema'
            content = if File.exist?('db/schema.rb')
                        File.read('db/schema.rb')
                      elsif File.exist?('db/structure.sql')
                        File.read('db/structure.sql')
                      else
                        '# Erro: Não encontrei nem db/schema.rb nem db/structure.sql'
                      end

          elsif uri == 'rails://routes'
            if defined?(::Rails)
              all_routes = ::Rails.application.routes.routes.map do |route|
                verb = route.verb.to_s
                path = route.path.spec.to_s

                reqs = route.requirements
                controller_action = "#{reqs[:controller]}##{reqs[:action]}"

                next if path.start_with?('/rails') || path.start_with?('/assets')

                "#{verb.ljust(8)} #{path.ljust(50)} #{controller_action}"
              end.compact.uniq

              if search_term && !search_term.empty?
                filtered_routes = all_routes.select { |r| r.include?(search_term) }
                content = filtered_routes.join("\n")

                content = "# Nenhuma rota encontrada para o termo: '#{search_term}'" if content.empty?
              else
                content = all_routes.join("\n")
              end

            else
              content = 'Erro: Rails não carregado.'
            end
          else
            content = "# Erro: Recurso desconhecido: #{uri}"
          end

          response = {
            jsonrpc: '2.0',
            id: request['id'],
            result: {
              contents: [
                {
                  uri: full_uri,
                  mimeType: 'text/plain',
                  text: content
                }
              ]
            }
          }
          send_response(response)

        when 'ping'
          send_response({ jsonrpc: '2.0', id: request['id'], result: {} })
        end
      end

      def send_response(response)
        puts response.to_json
        $stdout.flush
      end
    end
  end
end
