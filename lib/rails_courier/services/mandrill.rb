require "mandrill"
require "base64"

require "rails_courier/message_helper"

module RailsCourier
  module Services
    class Mandrill
      include RailsCourier::Services::MessageHelper

      attr_reader :api_key, :async, :mail, :options

      def initialize(mail, options = {})
        @mail = mail
        @api_key = options.fetch(:api_key)
        @async = options.fetch(:async, false)
        @options = options
      end

      def name
        :mandrill
      end

      def deliver!
        mandrill_api = ::Mandrill::API.new(api_key)
        mandrill_api.messages.send(mandrill_message, async)
      end

      def mandrill_message
        message = extract_params(nil_true_false: { auto_html: :auto_html,
                                                   auto_text: :auto_text,
                                                   important: :important,
                                                   inline_css: :inline_css,
                                                   track_clicks: :track_clicks,
                                                   track_opens: :track_opens,
                                                   url_strip_qs: :track_url_without_query_string,
                                                   view_content_link: :log_content },
                                 string: { bcc_address: :bcc_address,
                                           return_path_domain: :return_path_domain,
                                           signing_domain: :signing_domain,
                                           subaccount: :subaccount,
                                           tracking_domain: :tracking_domain })

        message[:important] ||= false

        message.merge!(from_email: from_email,
                       from_name: from_name,
                       headers: headers,
                       html: html_part,
                       subject: subject,
                       tags: tags,
                       text: text_part,
                       to: to)

        message[:attachments] = regular_attachments if attachments?(inline: false)
        message[:images] = inline_attachments if attachments?(inline: true)
        message
      end

      private

      def headers
        headers = {}
        value = mail["Reply-To"] || options[:reply_to]
        headers["Reply-To"] = value.to_s if value
        headers
      end

      def tags
        mail[:tags].to_s.split(", ").map { |tag| tag } +
          options[:tags].to_s.split(", ").map { |tag| tag }
      end

      def to
        %w(to cc bcc)
          .map { |field| hash_addresses(mail[field]) }
          .reject(&:nil?)
          .flatten
      end

      def hash_addresses(address_field)
        return nil unless address_field

        address_field.formatted.map do |address|
          address_obj = Mail::Address.new(address)
          {
            email: address_obj.address,
            name: address_obj.display_name,
            type: address_field.name.downcase
          }
        end
      end

      def regular_attachments
        attachments(inline: false).map do |attachment|
          { name: attachment[:name],
            type: attachment[:type],
            content: attachment[:content] }
        end
      end

      def inline_attachments
        attachments(inline: true).map do |attachment|
          { name: attachment[:name],
            type: attachment[:type],
            content: attachment[:content] }
        end
      end
    end
  end
end
