require "rails_courier/default"

module RailsCourier
  module Configurable
    attr_accessor :api_key, :service_name, :async, :auto_html, :auto_text, :important,
                  :inline_css, :track_clicks, :track_opens, :track_url_without_query_string,
                  :log_content, :bcc_address, :return_path_domain, :signing_domain,
                  :subaccount, :tracking_domain, :tags, :from

    class << self
      def keys
        @keys ||= [:api_key, :service_name, :async, :auto_html, :auto_text, :important,
                   :inline_css, :track_clicks, :track_opens, :track_url_without_query_string,
                   :log_content, :bcc_address, :return_path_domain, :signing_domain,
                   :subaccount, :tracking_domain, :tags, :from]
      end
    end

    def configure
      yield self
    end

    def reset!
      RailsCourier::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", RailsCourier::Default.options[key])
      end

      self
    end
    alias setup reset!

    def same_options?(opts)
      opts.hash == options.hash
    end

    def options
      Hash[RailsCourier::Configurable
           .keys.map { |key| [key, instance_variable_get(:"@#{key}")] }]
    end
  end
end
