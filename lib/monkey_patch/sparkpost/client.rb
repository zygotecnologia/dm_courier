require "rubygems"
require "json"
require "logger"
require "net/http"
require "json"

module SimpleSpark
  class Client
    def call(opts)
      method = opts[:method]
      path = opts[:path]
      body_values = opts[:body_values] || {}
      query_params = opts[:query_values] || {}
      extract_results = opts[:extract_results].nil? ? true : opts[:extract_results]

      path = "#{@base_path}#{path}"
      params = { path: path, headers: headers }
      params[:body] = JSON.generate(body_values) unless body_values.empty?
      params[:query] = query_params unless query_params.empty?

      if @debug
        logger.debug("Calling #{method}")
        logger.debug(params)
      end

      response = @session.send(method.to_s, params)

      if @debug
        logger.debug("Response #{response.status}")
        logger.debug(response)
      end

      fail Exceptions::GatewayTimeoutExceeded, "Received 504 from SparkPost API" if response.status == 504

      process_response(response, extract_results)

    rescue Excon::Errors::Timeout
      raise Exceptions::GatewayTimeoutExceeded
    end
  end
end
