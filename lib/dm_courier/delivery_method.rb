require "dm_courier/service_locator"

module DMCourier
  class DeliveryMethod
    include DMCourier::ServiceLocator
    include DMCourier::Configurable

    attr_reader :response

    def initialize(options = {})
      DMCourier::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", options[key] ||
                              DMCourier.instance_variable_get(:"@#{key}"))
      end
    end
    alias settings options

    def deliver!(mail)
      @response = service.new(mail, options).deliver!
    end
  end
end
