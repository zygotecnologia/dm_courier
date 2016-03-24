require "rails_courier/version"
require "rails_courier/errors"
require "rails_courier/configurable"
require "rails_courier/delivery_method"

require "rails_courier/railtie" if defined? Rails

module RailsCourier
  class << self
    include RailsCourier::Configurable

    def delivery_method
      return @delivery_method if defined?(@delivery_method) &&
                                 @delivery_method.same_options?(options)
      @delivery_method = RailsCourier::DeliveryMethod.new(options)
    end
  end
end

RailsCourier.setup
