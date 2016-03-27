require "dm_courier"

module DMCourier
  class Railtie < Rails::Railtie
    initializer "dm_courier.add_delivery_method" do
      ActiveSupport.on_load :action_mailer do
        ActionMailer::Base.add_delivery_method :dm_courier, DMCourier::DeliveryMethod
      end
    end
  end
end
