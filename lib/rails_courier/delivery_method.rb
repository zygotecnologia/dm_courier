require "rails_courier/service_locator"

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
      @response = service.new(mail, options).deliver!
    end
  end
end
