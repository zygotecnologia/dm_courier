require "simple_spark"
require "base64"

require "dm_courier/message_helper"
require "monkey_patch/sparkpost/client"

module DMCourier
  module Services
    class Sparkpost
      include DMCourier::Services::MessageHelper

      attr_reader :api_key, :mail, :options

      def initialize(mail, options = {})
        @mail = mail
        @api_key = options.fetch(:api_key)
        @options = options
      end

      def name
        :sparkpost
      end

      def deliver!
        sparkpost = ::SimpleSpark::Client.new(api_key: api_key)

        sparkpost.transmissions.create(sparkpost_message)
      end

      def sparkpost_message
        parameters = extract_params(nil_true_false: { inline_css: :inline_css,
                                                      click_tracking: :track_clicks,
                                                      open_tracking: :track_opens },
                                    string: { return_path: :return_path_domain })

        message = { options: {} }
        message[:options][:inline_css] = parameters[:inline_css] unless parameters[:inline_css].nil?
        message[:options][:click_tracking] = parameters[:click_tracking] unless parameters[:click_tracking].nil?
        message[:options][:open_tracking] = parameters[:open_tracking] unless parameters[:open_tracking].nil?

        message[:return_path] = parameters[:return_path] unless parameters[:return_path].nil?

        from = { email: from_email }
        from[:name] = from_name if from_name

        message[:content] = {
          from: from,
          subject: subject
        }

        message[:content][:reply_to] = reply_to if reply_to
        message[:content][:html] = html_part if html_part
        message[:content][:text] = text_part if text_part

        message[:recipients] = recipients
        message[:metadata] = metadata

        message[:content][:attachments] = regular_attachments if attachments?(inline: false)
        message[:content][:inline_images] = inline_attachments if attachments?(inline: true)
        message
      end

      private

      def reply_to
        value = mail["Reply-To"] || options[:reply_to]
        value.to_s if value
      end

      def recipients
        %w(to cc)
          .map { |field| hash_addresses(mail[field]) }
          .reject(&:nil?)
          .flatten
      end

      def hash_addresses(address_field)
        return nil unless address_field

        address_field.formatted.map do |address|
          address_obj = Mail::Address.new(address)
          {
            address: { email: address_obj.address }.tap do |hash|
              hash[:name] = address_obj.display_name if address_obj.display_name
            end
          }
        end
      end

      def regular_attachments
        attachments(inline: false).map do |attachment|
          { name: attachment[:name],
            type: attachment[:type],
            data: attachment[:content] }
        end
      end

      def inline_attachments
        attachments(inline: true).map do |attachment|
          { name: attachment[:name],
            type: attachment[:type],
            data: attachment[:content] }
        end
      end
    end
  end
end
