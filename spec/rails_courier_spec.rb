require "spec_helper"

describe RailsCourier do
  before do
    RailsCourier.reset!
  end

  after do
    RailsCourier.reset!
  end

  it "sets the defaults" do
    RailsCourier::Configurable.keys.each do |key|
      expect(RailsCourier.instance_variable_get(:"@#{key}")).to eq(RailsCourier::Default.send(key))
    end
  end

  describe ".configure" do
    RailsCourier::Configurable.keys.each do |key|
      it "sets the #{key.to_s.tr('_', ' ')}" do
        RailsCourier.configure do |config|
          config.send("#{key}=", key)
        end

        expect(RailsCourier.instance_variable_get("@#{key}")).to eq(key)
      end
    end
  end

  describe ".delivery_method" do
    it "creates a delivery method" do
      expect(RailsCourier.delivery_method).to be_kind_of(RailsCourier::DeliveryMethod)
    end

    it "cache the delivery method with the same options passed" do
      expect(RailsCourier.delivery_method).to be(RailsCourier.delivery_method)
    end

    it "returns a fresh delivery method when options are not the same" do
      dm = RailsCourier.delivery_method
      RailsCourier.api_key = "4321"
      dm_two = RailsCourier.delivery_method
      expect(dm).not_to eq(dm_two)
    end
  end
end
