require "rails_courier/default"

module RailsCourier
  module Configurable
    attr_accessor :api_key, :service_name

    class << self
      def keys
        @keys ||= [:api_key, :service_name]
      end
    end

    def configure
      yield self
    end

    def reset!
      RailsCourier::Configurable.keys.each do |key|
        instance_variable_set(:"@#{key}", RailsCourier::Default.options[key])
      end

      self
    end
    alias setup reset!

    def same_options?(opts)
      opts.hash == options.hash
    end

    private

    def options
      Hash[RailsCourier::Configurable
           .keys.map { |key| [key, instance_variable_get(:"@#{key}")] }]
    end
  end
end
