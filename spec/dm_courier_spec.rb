require "spec_helper"

describe DMCourier do
  before do
    DMCourier.reset!
  end

  after do
    DMCourier.reset!
  end

  it "sets the defaults" do
    DMCourier::Configurable.keys.each do |key|
      expect(DMCourier.instance_variable_get(:"@#{key}")).to eq(DMCourier::Default.send(key))
    end
  end

  describe ".configure" do
    DMCourier::Configurable.keys.each do |key|
      it "sets the #{key.to_s.tr('_', ' ')}" do
        DMCourier.configure do |config|
          config.send("#{key}=", key)
        end

        expect(DMCourier.instance_variable_get("@#{key}")).to eq(key)
      end
    end
  end

  describe ".delivery_method" do
    it "creates a delivery method" do
      expect(DMCourier.delivery_method).to be_kind_of(DMCourier::DeliveryMethod)
    end

    it "cache the delivery method with the same options passed" do
      expect(DMCourier.delivery_method).to be(DMCourier.delivery_method)
    end

    it "returns a fresh delivery method when options are not the same" do
      dm = DMCourier.delivery_method
      DMCourier.api_key = "4321"
      dm_two = DMCourier.delivery_method
      expect(dm).not_to eq(dm_two)
    end
  end
end
