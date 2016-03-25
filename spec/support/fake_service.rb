module RailsCourier
  module Services
    class FakeService
      attr_reader :mail, :options

      def initialize(mail, options)
        @options = options
        @mail = mail
      end

      def name
        :fake_service
      end

      def deliver!
        true
      end
    end
  end
end
