require "spec_helper"

describe DMCourier::Services::Sendgrid do
  let(:mail) { instance_double(Mail::Message) }
  let(:options) { { api_key: "1234" } }

  subject { described_class.new(mail, options) }

  it_behaves_like "a dm courier service"

  describe "#deliver!" do
    let(:response) { { "key" => "value" } }

    let(:api) { instance_double(SendGrid::Client, send: response) }

    before(:each) do
      allow(SendGrid::Client).to receive(:new).and_return(api)
      allow(subject).to receive(:sendgrid_message).and_return("Some mail object")
    end

    it "instantiates the sendgrid API with the configured key" do
      expect(SendGrid::Client).to receive(:new).with(options[:api_key]).and_return(api)

      subject.deliver!
    end

    it "sends the JSON version of sengrid message via the API" do
      expect(api).to receive(:send).with("Some mail object")

      subject.deliver!
    end

    it "returns the response from sending the message" do
      expect(subject.deliver!).to eq(response)
    end
  end

  describe "#sendgrid_message" do
    describe "attachments" do
      it "takes an attachment" do
        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative")
        mail.attachments["text.txt"] = {
          mime_type: "text/plain",
          content: "This is a test"
        }

        service = described_class.new(mail, options)
        expect(service.sendgrid_message.attachments.size).to eq(1)
        attachment = service.sendgrid_message.attachments.first

        expect(attachment[:name]).to eq("text.txt")
        expect(attachment[:file].content_type).to eq("text/plain")
        expect(attachment[:file].io.read).to eq("This is a test")
        expect(attachment[:file].original_filename).to eq("text.txt")
      end

      it "ignores inline attachments" do
        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative")
        mail.attachments.inline["text.txt"] = {
          mime_type: "text/plain",
          content: "This is a test"
        }

        service = described_class.new(mail, options)
        expect(service.sendgrid_message.attachments).to eq([])
      end
    end

    describe "#content" do
      it "takes an inline attachment" do
        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative")
        mail.attachments.inline["text.jpg"] = {
          mime_type: "image/jpg",
          content: "This is a test"
        }

        service = described_class.new(mail, options)
        expect(service.sendgrid_message.contents.size).to eq(1)
        attachment = service.sendgrid_message.contents.first

        expect(attachment[:name]).to eq("text.jpg")
        expect(attachment[:cid]).to eq(mail.attachments[0].cid)
        expect(attachment[:file].content_type).to eq("image/jpg")
        expect(attachment[:file].io.read).to eq("This is a test")
        expect(attachment[:file].original_filename).to eq("text.jpg")
      end

      it "ignores normal attachments" do
        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative")
        mail.attachments["text.txt"] = {
          mime_type: "text/plain",
          content: "This is a test"
        }

        service = described_class.new(mail, options)
        expect(service.sendgrid_message.contents).to eq([])
      end
    end

    describe "#bcc_address" do
      it "takes a bcc_address" do
        mail = new_mail(bcc_address: "bart@simpsons.com")
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.bcc).to eq("bart@simpsons.com")
      end

      it "does not take bcc_address value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.bcc).to eq([])
      end

      it "accept bcc_address in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(bcc_address: "bart@simpsons.com"))
        expect(service.sendgrid_message.bcc).to eq("bart@simpsons.com")
      end
    end

    describe "#from_email" do
      it "takes a single email" do
        mail = new_mail(from: "from_name@domain.tld")
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.from).to eq("from_name@domain.tld")
      end

      it "takes a single email with a display name" do
        mail = new_mail(from: "John Doe <from_name@domain.tld>")
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.from).to eq("from_name@domain.tld")
      end

      it "accept from_email in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(from: "bart@simpsons.com"))
        expect(service.sendgrid_message.from).to eq("bart@simpsons.com")
      end
    end

    describe "#from_name" do
      it "takes a single email" do
        mail = new_mail(from: "from_name@domain.tld")
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.from_name).to eq(nil)
      end

      it "takes a single email with a display name" do
        mail = new_mail(from: "John Doe <from_name@domain.tld>")
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.from_name).to eq("John Doe")
      end

      it "accept from_name in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(from: "John Doe <bart@simpsons.com>"))
        expect(service.sendgrid_message.from_name).to eq("John Doe")
      end
    end

    describe "#reply-to" do
      it "adds `Reply-To` header" do
        mail = new_mail(headers: { "Reply-To" => "name1@domain.tld" })
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.reply_to).to eq("name1@domain.tld")
      end

      it "accept reply_to in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(reply_to: "bart@simpsons.com"))
        expect(service.sendgrid_message.reply_to).to eq("bart@simpsons.com")
      end

      it "dont add the reply_to field if there isnt one" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.reply_to).to be_nil
      end
    end

    describe "#html" do
      it "takes a non-multipart message" do
        mail = new_mail(
          to: "name@domain.tld",
          body: "<html><body>Hello world!</body></html>"
        )

        service = described_class.new(mail, options)
        expect(service.sendgrid_message.html).to eq("<html><body>Hello world!</body></html>")
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
        expect(service.sendgrid_message.html).to eq("<html><body>Hello world!</body></html>")
      end
    end

    describe "#subject" do
      it "takes a subject" do
        mail = new_mail(subject: "Test Subject")
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.subject).to eq("Test Subject")
      end
    end

    describe "#text" do
      it "does not take a non-multipart message" do
        mail = new_mail(to: "name@domain.tld", body: "Hello world!")
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.text).to be_nil
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
        expect(service.sendgrid_message.text).to eq("Hello world!")
      end
    end

    describe "#to" do
      it "takes a single email" do
        mail = new_mail(to: "name@domain.tld")
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.to).to eq(["name@domain.tld"])
      end

      it "takes a single email with a display name" do
        mail = new_mail(to: "John Doe <name@domain.tld>")
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.to).to eq(["John Doe <name@domain.tld>"])
      end

      it "takes an array of emails" do
        mail = new_mail(to: ["name1@domain.tld", "name2@domain.tld"])
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.to).to eq(
          ["name1@domain.tld", "name2@domain.tld"]
        )
      end

      it "takes an array of emails with a display names" do
        mail = new_mail(
          to: ["John Doe <name1@domain.tld>", "Jane Smith <name2@domain.tld>"]
        )

        service = described_class.new(mail, options)
        expect(service.sendgrid_message.to).to eq(
          ["John Doe <name1@domain.tld>", "Jane Smith <name2@domain.tld>"]
        )
      end
    end

    describe "#cc" do
      it "takes a single email" do
        mail = new_mail(cc: "name@domain.tld")
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.cc).to eq(["name@domain.tld"])
      end

      it "takes a single email with a display name" do
        mail = new_mail(cc: "John Doe <name@domain.tld>")
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.cc).to eq(["John Doe <name@domain.tld>"])
      end

      it "takes an array of emails" do
        mail = new_mail(cc: ["name1@domain.tld", "name2@domain.tld"])
        service = described_class.new(mail, options)
        expect(service.sendgrid_message.cc).to eq(
          ["name1@domain.tld", "name2@domain.tld"]
        )
      end

      it "takes an array of emails with a display names" do
        mail = new_mail(
          cc: ["John Doe <name1@domain.tld>", "Jane Smith <name2@domain.tld>"]
        )

        service = described_class.new(mail, options)
        expect(service.sendgrid_message.cc).to eq(
          ["John Doe <name1@domain.tld>", "Jane Smith <name2@domain.tld>"]
        )
      end
    end
  end
end
