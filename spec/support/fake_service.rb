module RailsCourier
  module Services
    class FakeService
      attr_reader :messages, :options

      def initialize(options)
        @options = options
        @messages = []
      end

      def name
        :fake_service
      end

      def deliver!(message)
        @messages.push(message)
      end
    end
  end
end
