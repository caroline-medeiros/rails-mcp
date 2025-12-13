require "json"

module Rails
  module Mcp
    class Server
      def start
        warn "Rails MCP Server iniciado..."
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
        warn "Recebi método: #{request["method"]}"

        case request["method"]
        when "initialize"
          response = {
            jsonrpc: "2.0",
            id: request["id"],
            result: {
              protocolVersion: "2024-11-05",
              capabilities: {
                resources: {}
              },
              serverInfo: {
                name: "rails-mcp",
                version: "0.1.0"
              }
            }
          }
          send_response(response)

        when "notifications/initialized"
          warn "Conexão estabelecida!"

        when "resources/list"
          response = {
            jsonrpc: "2.0",
            id: request["id"],
            result: {
              resources: [
                {
                  uri: "rails://schema",
                  name: "Schema do Banco",
                  mimeType: "application/ruby"
                },
                {
                  uri: "rails://routes",
                  name: "Rotas da Aplicação",
                  mimeType: "text/plain"
                }
              ]
            }
          }
          send_response(response)

        when "resources/read"
          uri = request.dig("params", "uri")
          content = ""

          if uri == "rails://schema"
            content = if File.exist?("db/schema.rb")
                        File.read("db/schema.rb")
                      else
                        "# Erro: Arquivo db/schema.rb não encontrado aqui na pasta da gem."
                      end
          elsif uri == "rails://routes"
            if defined?(::Rails)
              routes = ::Rails.application.routes.routes.map do |route|
                verb = route.verb.to_s
                path = route.path.spec.to_s

                next if path.start_with?("/rails") || path.start_with?("/assets")

                "#{verb.ljust(8)} #{path}"
              end.compact.uniq.join("\n")

              content = routes
            else
              content = "Erro: O Rails não está carregado. Rode o comando na raiz do projeto."
            end
          else
            content = "# Erro: Recurso desconhecido ou não implementado: #{uri}"
          end

          response = {
            jsonrpc: "2.0",
            id: request["id"],
            result: {
              contents: [
                {
                  uri: uri,
                  mimeType: "text/plain",
                  text: content
                }
              ]
            }
          }
          send_response(response)

        when "ping"
          send_response({ jsonrpc: "2.0", id: request["id"], result: {} })
        end
      end

      def send_response(response)
        puts response.to_json
        $stdout.flush
      end
    end
  end
end
