require "rails_courier/service_locator"
require "rails_courier/message"

module RailsCourier
  class DeliveryMethod
    include RailsCourier::ServiceLocator
    include RailsCourier::Configurable

    attr_reader :response

    def initialize(options = {})
      RailsCourier::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", options[key] ||
                              RailsCourier.instance_variable_get(:"@#{key}"))
      end
    end

    def deliver!(mail)
      message = RailsCourier::Message.new(mail)

      @response = service.deliver!(message)
    end
  end
end
