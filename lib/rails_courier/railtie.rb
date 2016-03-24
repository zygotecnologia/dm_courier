require "rails_courier"

module RailsCourier
  class Railtie < Rails::Railtie
    initializer "rails_courier.add_delivery_method" do
      ActiveSupport.on_load :action_mailer do
        ActionMailer::Base.add_delivery_method :rails_courier, RailsCourier::DeliveryMethod
      end
    end
  end
end
