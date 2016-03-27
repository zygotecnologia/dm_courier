require "sendgrid-ruby"
require "base64"

require "dm_courier/message_helper"

module DMCourier
  module Services
    class Sendgrid
      include DMCourier::Services::MessageHelper

      attr_reader :api_key, :mail, :options

      def initialize(mail, options = {})
        @mail = mail
        @api_key = options.fetch(:api_key)
        @options = options
      end

      def name
        :sendgrid
      end

      def deliver!
        sendgrid_api = ::SendGrid::Client.new(api_key)
        sendgrid_api.send(sendgrid_message)
      end

      def sendgrid_message
        message = { to: (mail[:to].formatted if mail[:to]),
                    cc: (mail[:cc].formatted if mail[:cc]),
                    bcc: return_string_value(:bcc_address),
                    from: from_email,
                    from_name: from_name,
                    subject: subject,
                    html: html_part,
                    text: text_part,
                    reply_to: reply_to }

        message[:attachments] = regular_attachments

        ::SendGrid::Mail.new(message) do |mail|
          inline_attachments.each do |attachment|
            mail.contents << attachment
          end
        end
      end

      private

      def reply_to
        value = mail["Reply-To"] || options[:reply_to]
        value.to_s if value
      end

      def regular_attachments
        mail.attachments.map do |attachment|
          next if attachment.inline?

          { file: Faraday::UploadIO.new(StringIO.new(attachment.body.decoded),
                                        attachment.mime_type,
                                        attachment.filename),
            name:  attachment.filename }
        end.compact
      end

      def inline_attachments
        mail.attachments.map do |attachment|
          next unless attachment.inline?

          { file: Faraday::UploadIO.new(StringIO.new(attachment.body.decoded),
                                        attachment.mime_type,
                                        attachment.filename),
            cid: attachment.cid,
            name:  attachment.filename }
        end.compact
      end
    end
  end
end
