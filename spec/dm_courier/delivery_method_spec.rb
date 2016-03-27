require "spec_helper"

describe DMCourier::DeliveryMethod do
  before do
    DMCourier.reset!
  end

  after do
    DMCourier.reset!
  end

  describe "module configuration" do
    before do
      DMCourier.reset!

      DMCourier.configure do |config|
        DMCourier::Configurable.keys.each do |key|
          config.send("#{key}=", "Some #{key}")
        end
      end
    end

    after do
      DMCourier.reset!
    end

    it "inherits the module configuration" do
      dm = DMCourier::DeliveryMethod.new
      DMCourier::Configurable.keys.each do |key|
        expect(dm.instance_variable_get(:"@#{key}")).to eq("Some #{key}")
      end
    end

    describe "with class level configuration" do
      before do
        @opts = {
          service_name: "sparkpost",
          api_key: "1234"
        }
      end

      it "overrides module configuration" do
        dm = DMCourier::DeliveryMethod.new(@opts)
        expect(dm.instance_variable_get(:@service_name)).to eq("sparkpost")
        expect(dm.api_key).to eq("1234")
      end
    end
  end

  describe "#deliver!" do
    let(:mail) { instance_double(Mail::Message) }

    before do
      @options = {}
      DMCourier.configure do |config|
        DMCourier::Configurable.keys.each do |key|
          @options[key] = "Some #{key}"
          config.send("#{key}=", "Some #{key}")
        end
      end
      @options[:service_name] = :fake_service
    end

    subject { described_class.new(service_name: :fake_service) }
    let(:fake_service) { instance_double(DMCourier::Services::FakeService, deliver!: "response") }

    it "raises when service is not defined" do
      dm = DMCourier::DeliveryMethod.new(service_name: nil)

      expect { dm.deliver!(mail) }
        .to raise_error(DMCourier::InvalidService)
    end

    it "raises when service is invalid" do
      dm = DMCourier::DeliveryMethod.new(service_name: "invalid_service")

      expect { dm.deliver!(mail) }
        .to raise_error(DMCourier::InvalidService)
    end

    it "instantiates the service" do
      expect(DMCourier::Services::FakeService).to receive(:new).with(mail, @options).and_return(fake_service)

      subject.deliver!(mail)
    end

    it "put the response on the response variable" do
      expect(DMCourier::Services::FakeService).to receive(:new).and_return(fake_service)

      subject.deliver!(mail)

      expect(subject.response).to eq("response")
    end
  end
end
