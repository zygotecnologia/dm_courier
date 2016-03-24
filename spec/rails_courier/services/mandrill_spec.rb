require "spec_helper"

describe RailsCourier::Services::Mandrill do
  let(:mail) { instance_double(Mail::Message) }
  let(:options) { { api_key: "1234" } }

  subject { described_class.new(mail, options) }

  it_behaves_like "a rails courier service"

  describe "#deliver!" do
    let(:response) { { "key" => "value" } }

    let(:api_messages) { instance_double(Mandrill::Messages, send: response) }
    let(:api) { instance_double(Mandrill::API, messages: api_messages) }

    before(:each) do
      allow(Mandrill::API).to receive(:new).and_return(api)
      allow(subject).to receive(:mandrill_message).and_return("Some message JSON")
    end

    it "instantiates the mandrill API with the configured key" do
      expect(Mandrill::API).to receive(:new).with(options[:api_key]).and_return(api)

      subject.deliver!
    end

    it "sends the JSON version of Mandrill message via the API" do
      expect(api_messages).to receive(:send).with("Some message JSON", false)

      subject.deliver!
    end

    it "send async the JSON version of the mandrill message via the API" do
      service = described_class.new(mail, options.merge(async: true))

      allow(service).to receive(:mandrill_message).and_return("Some message JSON")
      expect(api_messages).to receive(:send).with("Some message JSON", true)

      service.deliver!
    end

    it "returns the response from sending the message" do
      expect(subject.deliver!).to eq(response)
    end
  end

  describe "#mandrill_message" do
    describe "attachments" do
      it "takes an attachment" do
        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative")
        mail.attachments["text.txt"] = {
          mime_type: "text/plain",
          content: "This is a test"
        }

        service = described_class.new(mail, options)
        expect(service.mandrill_message[:attachments]).to eq(
          [{ name: "text.txt", type: "text/plain", content: "VGhpcyBpcyBhIHRlc3Q=\n" }]
        )
      end

      it "ignores inline attachments" do
        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative")
        mail.attachments.inline["text.txt"] = {
          mime_type: "text/plain",
          content: "This is a test"
        }

        service = described_class.new(mail, options)
        expect(service.mandrill_message).not_to have_key(:attachments)
      end
    end

    describe "auto_html" do
      it "takes a auto_html with true" do
        mail = new_mail(auto_html: true)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:auto_html]).to be true
      end

      it "takes a auto_html with false" do
        mail = new_mail(auto_html: false)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:auto_html]).to be false
      end

      it "does not take an auto_html value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:auto_html]).to be_nil
      end

      it "accept auto_html in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(auto_html: true))
        expect(service.mandrill_message[:auto_html]).to be true
      end
    end

    describe "#auto_text" do
      it "takes a auto_text with true" do
        mail = new_mail(auto_text: true)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:auto_text]).to be true
      end

      it "takes a auto_text with false" do
        mail = new_mail(auto_text: false)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:auto_text]).to be false
      end

      it "does not take an auto_text value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:auto_text]).to be_nil
      end

      it "accept auto_text in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(auto_text: true))
        expect(service.mandrill_message[:auto_text]).to be true
      end
    end

    describe "#bcc_address" do
      it "takes a bcc_address" do
        mail = new_mail(bcc_address: "bart@simpsons.com")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:bcc_address]).to eq("bart@simpsons.com")
      end

      it "does not take bcc_address value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:bcc_address]).to be_nil
      end

      it "accept bcc_address in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(bcc_address: "bart@simpsons.com"))
        expect(service.mandrill_message[:bcc_address]).to eq("bart@simpsons.com")
      end
    end

    describe "#from_email" do
      it "takes a single email" do
        mail = new_mail(from: "from_name@domain.tld")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:from_email]).to eq("from_name@domain.tld")
      end

      it "takes a single email with a display name" do
        mail = new_mail(from: "John Doe <from_name@domain.tld>")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:from_email]).to eq("from_name@domain.tld")
      end

      it "accept from_email in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(from: "bart@simpsons.com"))
        expect(service.mandrill_message[:from_email]).to eq("bart@simpsons.com")
      end
    end

    describe "#from_name" do
      it "takes a single email" do
        mail = new_mail(from: "from_name@domain.tld")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:from_name]).to eq(nil)
      end

      it "takes a single email with a display name" do
        mail = new_mail(from: "John Doe <from_name@domain.tld>")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:from_name]).to eq("John Doe")
      end

      it "accept from_name in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(from: "John Doe <bart@simpsons.com>"))
        expect(service.mandrill_message[:from_name]).to eq("John Doe")
      end
    end

    describe "#headers" do
      def check_header(header)
        mail = new_mail(headers: header)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:headers]).to eq(header)
      end

      it "adds `Reply-To` header" do
        check_header "Reply-To" => "name1@domain.tld"
      end

      it "accept reply_to in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(reply_to: "bart@simpsons.com"))
        expect(service.mandrill_message[:headers]).to eq("Reply-To" => "bart@simpsons.com")
      end
    end

    describe "#html" do
      it "takes a non-multipart message" do
        mail = new_mail(
          to: "name@domain.tld",
          body: "<html><body>Hello world!</body></html>"
        )

        service = described_class.new(mail, options)
        expect(service.mandrill_message[:html]).to eq("<html><body>Hello world!</body></html>")
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
        expect(service.mandrill_message[:html]).to eq("<html><body>Hello world!</body></html>")
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
        expect(service.mandrill_message[:images]).to eq(
          [{ name: mail.attachments[0].cid,
             type: "image/jpg",
             content: "VGhpcyBpcyBhIHRlc3Q=\n" }]
        )
      end

      it "ignores normal attachments" do
        mail = new_mail(to: "name@domain.tld", content_type: "multipart/alternative")
        mail.attachments["text.txt"] = {
          mime_type: "text/plain",
          content: "This is a test"
        }

        service = described_class.new(mail, options)
        expect(service.mandrill_message).not_to have_key(:images)
      end
    end

    describe "#important" do
      it "takes an important email" do
        mail = new_mail(important: true)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:important]).to be true
      end

      it "takes a non-important email" do
        mail = new_mail(important: false)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:important]).to be false
      end

      it "takes a default important value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:important]).to be false
      end

      it "accept important in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(important: true))
        expect(service.mandrill_message[:important]).to be true
      end
    end

    describe "#inline_css" do
      it "takes a inline_css with true" do
        mail = new_mail(inline_css: true)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:inline_css]).to be true
      end

      it "takes a inline_css with false" do
        mail = new_mail(inline_css: false)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:inline_css]).to be false
      end

      it "does not take an inline_css value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:inline_css]).to be_nil
      end

      it "accept inline_css in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(inline_css: true))
        expect(service.mandrill_message[:inline_css]).to be true
      end
    end

    describe "#return_path_domain" do
      it "takes a return_path_domain" do
        mail = new_mail(return_path_domain: "return_path_domain.com")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:return_path_domain]).to eq("return_path_domain.com")
      end

      it "does not take return_path_domain value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:return_path_domain]).to be_nil
      end

      it "accept return_path_domain in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(return_path_domain: "return_path.com"))
        expect(service.mandrill_message[:return_path_domain]).to eq("return_path.com")
      end
    end

    describe "#signing_domain" do
      it "takes a signing_domain" do
        mail = new_mail(signing_domain: "signing_domain.com")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:signing_domain]).to eq("signing_domain.com")
      end

      it "does not take signing_domain value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:signing_domain]).to be_nil
      end

      it "accept signing_domain in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(signing_domain: "signing_domain.com"))
        expect(service.mandrill_message[:signing_domain]).to eq("signing_domain.com")
      end
    end

    describe "#subaccount" do
      it "takes a subaccount" do
        mail = new_mail(subaccount: "abc123")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:subaccount]).to eq("abc123")
      end

      it "does not take subaccount value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:subaccount]).to be_nil
      end

      it "accept subaccount in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(subaccount: "abc123"))
        expect(service.mandrill_message[:subaccount]).to eq("abc123")
      end
    end

    describe "#subject" do
      it "takes a subject" do
        mail = new_mail(subject: "Test Subject")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:subject]).to eq("Test Subject")
      end
    end

    describe "#tags" do
      it "takes a tag" do
        mail = new_mail(tags: "test_tag")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:tags]).to eq(["test_tag"])
      end

      it "takes an array of tags" do
        mail = new_mail(tags: %w(test_tag1 test_tag2))
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:tags]).to eq(%w(test_tag1 test_tag2))
      end

      it "accept tags in options" do
        mail = new_mail(tags: "test_tag1")
        service = described_class.new(mail, options.merge(tags: "abc123"))
        expect(service.mandrill_message[:tags]).to eq(%w(test_tag1 abc123))
      end
    end

    describe "#text" do
      it "does not take a non-multipart message" do
        mail = new_mail(to: "name@domain.tld", body: "Hello world!")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:text]).to eq(nil)
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
        expect(service.mandrill_message[:text]).to eq("Hello world!")
      end
    end

    describe "#to" do
      it "takes a single email" do
        mail = new_mail(to: "name@domain.tld")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:to]).to eq([{ email: "name@domain.tld", name: nil, type: "to" }])
      end

      it "takes a single email with a display name" do
        mail = new_mail(to: "John Doe <name@domain.tld>")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:to]).to eq(
          [{ email: "name@domain.tld", name: "John Doe", type: "to" }]
        )
      end

      it "takes an array of emails" do
        mail = new_mail(to: ["name1@domain.tld", "name2@domain.tld"])
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:to]).to eq(
          [
            { email: "name1@domain.tld", name: nil, type: "to" },
            { email: "name2@domain.tld", name: nil, type: "to" }
          ]
        )
      end

      it "takes an array of emails with a display names" do
        mail = new_mail(
          to: ["John Doe <name1@domain.tld>", "Jane Smith <name2@domain.tld>"]
        )

        service = described_class.new(mail, options)
        expect(service.mandrill_message[:to]).to eq(
          [
            { email: "name1@domain.tld", name: "John Doe", type: "to" },
            { email: "name2@domain.tld", name: "Jane Smith", type: "to" }
          ]
        )
      end

      it "combines to, cc, and bcc fields" do
        mail = new_mail(
          to: "John Doe <name1@domain.tld>",
          cc: "Jane Smith <name2@domain.tld>",
          bcc: "Jenny Craig <name3@domain.tld>"
        )

        service = described_class.new(mail, options)
        expect(service.mandrill_message[:to]).to eq(
          [
            { email: "name1@domain.tld", name: "John Doe", type: "to" },
            { email: "name2@domain.tld", name: "Jane Smith", type: "cc" },
            { email: "name3@domain.tld", name: "Jenny Craig", type: "bcc" }
          ]
        )
      end
    end

    describe "#track_clicks" do
      it "takes a track_clicks with true" do
        mail = new_mail(track_clicks: true)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:track_clicks]).to be true
      end

      it "takes a track_clicks with false" do
        mail = new_mail(track_clicks: false)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:track_clicks]).to be false
      end

      it "does not take a track_clicks value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:track_clicks]).to be_nil
      end

      it "accept track_clicks in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(track_clicks: true))
        expect(service.mandrill_message[:track_clicks]).to be true
      end
    end

    describe "#track_opens" do
      it "takes a track_opens with true" do
        mail = new_mail(track_opens: true)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:track_opens]).to be true
      end

      it "takes a track_opens with false" do
        mail = new_mail(track_opens: false)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:track_opens]).to be false
      end

      it "does not take a track_opens value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:track_opens]).to be_nil
      end

      it "accept track_opens in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(track_opens: true))
        expect(service.mandrill_message[:track_opens]).to be true
      end
    end

    describe "#tracking_domain" do
      it "takes a tracking_domain" do
        mail = new_mail(tracking_domain: "tracking_domain.com")
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:tracking_domain]).to eq("tracking_domain.com")
      end

      it "does not take tracking_domain value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:tracking_domain]).to be_nil
      end

      it "accept tracking_domain in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(tracking_domain: "domain.com"))
        expect(service.mandrill_message[:tracking_domain]).to eq("domain.com")
      end
    end

    describe "#track_url_without_query_string" do
      it "takes a track_url_without_query_string with true" do
        mail = new_mail(track_url_without_query_string: true)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:url_strip_qs]).to be true
      end

      it "takes a url_strip_qs with false" do
        mail = new_mail(track_url_without_query_string: false)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:url_strip_qs]).to be false
      end

      it "does not take an url_strip_qs value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:url_strip_qs]).to be_nil
      end

      it "accept track_url_without_query_string in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(track_url_without_query_string: true))
        expect(service.mandrill_message[:url_strip_qs]).to be true
      end
    end

    describe "#log_content" do
      it "takes a log_content with true" do
        mail = new_mail(log_content: true)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:view_content_link]).to be true
      end

      it "takes a log_content with false" do
        mail = new_mail(log_content: false)
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:view_content_link]).to be false
      end

      it "does not take log_content value" do
        mail = new_mail
        service = described_class.new(mail, options)
        expect(service.mandrill_message[:view_content_link]).to be_nil
      end

      it "accept log_content in options" do
        mail = new_mail
        service = described_class.new(mail, options.merge(log_content: true))
        expect(service.mandrill_message[:view_content_link]).to be true
      end
    end
  end
end
