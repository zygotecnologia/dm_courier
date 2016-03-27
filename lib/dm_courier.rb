require "dm_courier/version"
require "dm_courier/errors"
require "dm_courier/configurable"
require "dm_courier/delivery_method"

require "dm_courier/railtie" if defined? Rails

module DMCourier
  class << self
    include DMCourier::Configurable

    def delivery_method
      return @delivery_method if defined?(@delivery_method) &&
                                 @delivery_method.same_options?(options)
      @delivery_method = DMCourier::DeliveryMethod.new(options)
    end
  end
end

DMCourier.setup
