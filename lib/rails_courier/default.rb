module RailsCourier
  module Default
    class << self
      def options
        Hash[RailsCourier::Configurable.keys.map { |key| [key, send(key)] }]
      end

      def api_key
        ENV['RAILS_COURIER_API_KEY']
      end

      def service
        ENV['RAILS_COURIER_SERVICE']
      end
    end
  end
end
