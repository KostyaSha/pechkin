require 'open-uri'
require 'net/http'
require 'uri'
require 'json'

module Pechkin
  # Base connector
  class Connector
    def send_message(chat, message, options); end

    def post_data(url, data, headers: {})
      uri = URI.parse(url)
      headers = { 'Content-Type' => 'application/json' }.merge(headers)
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.request_uri, headers)
      request.body = data.to_json

      http.request(request)
    end
  end

  class TelegramConnector < Connector #:nodoc:
    def initialize(bot_token)
      @bot_token = bot_token
    end

    def send_message(chat_id, message, options = {})
      options = { markup: 'HTML' }.update(options)
      params = options.update(chat_id: chat_id, text: message)

      response = post_data(method_url('sendMessage'), params)
      [chat_id, response.code.to_i, response.body]
    end

    private

    def method_url(method)
      "https://api.telegram.org/bot#{@bot_token}/#{method}"
    end
  end

  class SlackConnector < Connector # :nodoc:
    def initialize(bot_token)
      @headers = { 'Authorization' => "Bearer #{bot_token}" }
    end

    def send_message(chat, message, options)
      params = options.update(channel: chat, text: message)
      url = 'https://slack.com/api/chat.postMessage'
      response = post_data(url, params, headers: @headers)

      [chat_id, response.code.to_i, response.body]
    end
  end
end