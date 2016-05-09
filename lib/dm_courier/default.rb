module DMCourier
  module Default
    class << self
      def options
        Hash[DMCourier::Configurable.keys.map { |key| [key, send(key)] }]
      end

      def api_key
        ENV["DM_COURIER_API_KEY"]
      end

      def service_name
        ENV["DM_COURIER_SERVICE"]
      end

      def async
        false
      end

      def auto_html
        nil
      end

      def auto_text
        nil
      end

      def important
        nil
      end

      def inline_css
        nil
      end

      def track_clicks
        nil
      end

      def track_opens
        nil
      end

      def track_url_without_query_string
        nil
      end

      def log_content
        nil
      end

      def bcc_address
        nil
      end

      def return_path_domain
        nil
      end

      def signing_domain
        nil
      end

      def subaccount
        nil
      end

      def tracking_domain
        nil
      end

      def tags
        nil
      end

      def from
        nil
      end

      def return_response
        true
      end
    end
  end
end
