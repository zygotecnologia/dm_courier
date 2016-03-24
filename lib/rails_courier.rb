require "rails_courier/version"
require "rails_courier/configurable"

module RailsCourier
  class << self
    include RailsCourier::Configurable
  end
end

RailsCourier.setup
