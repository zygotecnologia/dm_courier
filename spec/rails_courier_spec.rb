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
end
