require "net/http"
require "json"

module SparkPost
  module Request
    def request(url, api_key, data)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      headers = {
        "User-Agent" => "ruby-sparkpost/" + VERSION,
        "Content-Type" => "application/json",
        "Authorization" => api_key
      }
      req = Net::HTTP::Post.new(uri.path, headers)
      req.body = JSON.generate(data)

      process_response(http.request(req))
    end
  end
end
