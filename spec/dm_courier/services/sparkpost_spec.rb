require "spec_helper"

describe DMCourier::Services::Sparkpost do
  let(:mail) { instance_double(Mail::Message) }
  let(:options) { { api_key: "1234" } }

  subject { described_class.new(mail, options) }

  it_behaves_like "a dm courier service"

  describe "#deliver!" do
    let(:response) { { "key" => "value" } }

    let(:api_transmission) { instance_double(SimpleSpark::Endpoints::Transmissions, create: response) }
    let(:api) { instance_double(SimpleSpark::Client, transmissions: api_transmission) }

    before(:each) do
      allow(SimpleSpark::Client).to receive(:new).and_return(api)
      allow(subject).to receive(:sparkpost_message).and_return("some options")
    end

    it "instantiates the sparkpost API with the configured key" do
      expect(SimpleSpark::Client).to receive(:new).with(options[:api_key]).and_return(api)

      subject.deliver!
    end

    it "sends the JSON version of SparkPost message via the API" do
      expect(api_transmission).to receive(:create).with("some options")

      subject.deliver!
    end

    it "returns the response from sending the message" do
      expect(subject.deliver!).to eq(response)
    end
  end

  describe "#sparkpost_message" do
    describe "attachments" do
      it "takes an attachment" do
        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative")
        mail.attachments["text.txt"] = {
          mime_type: "text/plain",
          content: "This is a test"
        }

        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content][:attachments]).to eq(
          [{ name: "text.txt", type: "text/plain", data: "VGhpcyBpcyBhIHRlc3Q=\n" }]
        )
      end

      it "ignores inline attachments" do
        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative")
        mail.attachments.inline["text.txt"] = {
          mime_type: "text/plain",
          content: "This is a test"
        }

        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content]).not_to have_key(:attachments)
      end
    end

    describe "#from_email" do
      it "takes a single email" do
        mail = new_mail(from: "from_name@domain.tld")
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content][:from][:email]).to eq("from_name@domain.tld")
      end

      it "takes a single email with a display name" do
        mail = new_mail(from: "John Doe <from_name@domain.tld>")
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content][:from][:email]).to eq("from_name@domain.tld")
      end

      it "accept from_email in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(from: "bart@simpsons.com"))
        expect(service.sparkpost_message[:content][:from][:email]).to eq("bart@simpsons.com")
      end
    end

    describe "#from_name" do
      it "takes a single email" do
        mail = new_mail(from: "from_name@domain.tld")
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content][:from]).not_to have_key(:name)
      end

      it "takes a single email with a display name" do
        mail = new_mail(from: "John Doe <from_name@domain.tld>")
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content][:from][:name]).to eq("John Doe")
      end

      it "accept from_name in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(from: "John Doe <bart@simpsons.com>"))
        expect(service.sparkpost_message[:content][:from][:name]).to eq("John Doe")
      end
    end

    describe "#reply_to" do
      it "adds `Reply-To` header" do
        mail = new_mail(headers: { "Reply-To" => "name1@domain.tld" })
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content][:reply_to]).to eq("name1@domain.tld")
      end

      it "accept reply_to in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(reply_to: "bart@simpsons.com"))
        expect(service.sparkpost_message[:content][:reply_to]).to eq("bart@simpsons.com")
      end

      it "dont add the reply_to field if there isnt one" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content]).not_to have_key(:reply_to)
      end
    end

    describe "#html" do
      it "takes a non-multipart message" do
        mail = new_mail(
          to: "name@domain.tld",
          body: "<html><body>Hello world!</body></html>"
        )

        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content][:html]).to eq("<html><body>Hello world!</body></html>")
      end

      it "takes a multipart message" do
        html_part = Mail::Part.new do
          content_type "text/html"
          body "<html><body>Hello world!</body></html>"
        end

        text_part = Mail::Part.new do
          content_type "text/plain"
          body "Hello world!"
        end

        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative") do |p|
          p.html_part = html_part
          p.text_part = text_part
        end

        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content][:html]).to eq("<html><body>Hello world!</body></html>")
      end
    end

    describe "#images" do
      it "takes an inline attachment" do
        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative")
        mail.attachments.inline["text.jpg"] = {
          mime_type: "image/jpg",
          content: "This is a test"
        }

        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content][:inline_images]).to eq(
          [{ name: mail.attachments[0].cid,
             type: "image/jpg",
             data: "VGhpcyBpcyBhIHRlc3Q=\n" }]
        )
      end

      it "ignores normal attachments" do
        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative")
        mail.attachments["text.txt"] = {
          mime_type: "text/plain",
          content: "This is a test"
        }

        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content]).not_to have_key(:inline_images)
      end
    end

    describe "#inline_css" do
      it "takes a inline_css with true" do
        mail = new_mail(inline_css: true)
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:options][:inline_css]).to be true
      end

      it "takes a inline_css with false" do
        mail = new_mail(inline_css: false)
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:options][:inline_css]).to be false
      end

      it "does not take an inline_css value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:options]).not_to have_key(:inline_css)
      end

      it "accept inline_css in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(inline_css: true))
        expect(service.sparkpost_message[:options][:inline_css]).to be true
      end
    end

    describe "#return_path_domain" do
      it "takes a return_path_domain" do
        mail = new_mail(return_path_domain: "return_path_domain.com")
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:return_path]).to eq("return_path_domain.com")
      end

      it "does not take return_path_domain value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.sparkpost_message).not_to have_key(:return_path)
      end

      it "accept return_path_domain in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(return_path_domain: "return_path.com"))
        expect(service.sparkpost_message[:return_path]).to eq("return_path.com")
      end
    end

    describe "#subject" do
      it "takes a subject" do
        mail = new_mail(subject: "Test Subject")
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content][:subject]).to eq("Test Subject")
      end
    end

    describe "#text" do
      it "does not take a non-multipart message" do
        mail = new_mail(to: "name@domain.tld", body: "Hello world!")
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content]).not_to have_key(:text)
      end

      it "takes a multipart message" do
        html_part = Mail::Part.new do
          content_type "text/html"
          body "<html><body>Hello world!</body></html>"
        end

        text_part = Mail::Part.new do
          content_type "text/plain"
          body "Hello world!"
        end

        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative") do |p|
          p.html_part = html_part
          p.text_part = text_part
        end
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:content][:text]).to eq("Hello world!")
      end
    end

    describe "#to" do
      it "takes a single email" do
        mail = new_mail(to: "name@domain.tld")
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:recipients]).to eq(
          [{ address: { email: "name@domain.tld" } }]
        )
      end

      it "takes a single email with a display name" do
        mail = new_mail(to: "John Doe <name@domain.tld>")
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:recipients]).to eq(
          [{ address: { email: "name@domain.tld", name: "John Doe" } }]
        )
      end

      it "takes an array of emails" do
        mail = new_mail(to: ["name1@domain.tld", "name2@domain.tld"])
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:recipients]).to eq(
          [
            { address: { email: "name1@domain.tld" } },
            { address: { email: "name2@domain.tld" } }
          ]
        )
      end

      it "takes an array of emails with a display names" do
        mail = new_mail(
          to: ["John Doe <name1@domain.tld>", "Jane Smith <name2@domain.tld>"]
        )

        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:recipients]).to eq(
          [
            { address: { email: "name1@domain.tld", name: "John Doe" } },
            { address: { email: "name2@domain.tld", name: "Jane Smith" } }
          ]
        )
      end

      it "combines to and ccfields" do
        mail = new_mail(
          to: "John Doe <name1@domain.tld>",
          cc: "Jane Smith <name2@domain.tld>"
        )

        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:recipients]).to eq(
          [
            { address: { email: "name1@domain.tld", name: "John Doe" } },
            { address: { email: "name2@domain.tld", name: "Jane Smith" } },
          ]
        )
      end
    end

    describe "#track_clicks" do
      it "takes a track_clicks with true" do
        mail = new_mail(track_clicks: true)
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:options][:click_tracking]).to be true
      end

      it "takes a track_clicks with false" do
        mail = new_mail(track_clicks: false)
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:options][:click_tracking]).to be false
      end

      it "does not take a track_clicks value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:options]).not_to have_key(:click_tracking)
      end

      it "accept track_clicks in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(track_clicks: true))
        expect(service.sparkpost_message[:options][:click_tracking]).to be true
      end
    end

    describe "#track_opens" do
      it "takes a track_opens with true" do
        mail = new_mail(track_opens: true)
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:options][:open_tracking]).to be true
      end

      it "takes a track_opens with false" do
        mail = new_mail(track_opens: false)
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:options][:open_tracking]).to be false
      end

      it "does not take a track_opens value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.sparkpost_message[:options]).not_to have_key(:open_tracking)
      end

      it "accept track_opens in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(track_opens: true))
        expect(service.sparkpost_message[:options][:open_tracking]).to be true
      end
    end
  end
end
