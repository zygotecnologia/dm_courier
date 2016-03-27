require "base64"

module DMCourier
  module Services
    module MessageHelper
      def extract_params(params)
        json = {}

        json
          .merge!(Hash[
            params[:nil_true_false].map { |name, key| [name.to_sym, nil_true_false?(key.to_sym)] }
          ]) if params.key?(:nil_true_false)

        json
          .merge!(Hash[
            params[:string].map { |name, key| [name.to_sym, return_string_value(key.to_sym)] }
          ]) if params.key?(:string)

        json
      end

      def from_email
        from.address if from_address
      end

      def from_name
        from.display_name if from_address
      end

      def from
        Mail::Address.new(from_address)
      end

      def from_address
        mail[:from] ? mail[:from].formatted.first : options[:from]
      end

      def text_part
        return mail.text_part.body.decoded if mail.multipart? && mail.text_part
        nil
      end

      def html_part
        mail.html_part ? mail.html_part.body.decoded : mail.body.decoded
      end

      def subject
        mail.subject
      end

      def return_string_value(field)
        value = fallback_options(field)
        value ? value.to_s : nil
      end

      def nil_true_false?(field)
        value = fallback_options(field)
        return nil if value.nil?
        value.to_s == "true" ? true : false
      end

      def fallback_options(field)
        mail[field] || options[field]
      end

      def attachments(filter = {})
        Enumerator.new do |y|
          attachments = mail.attachments
          attachments = if filter[:inline]
                          attachments.select(&:inline?)
                        else
                          attachments.reject(&:inline?)
                        end if filter.key?(:inline)

          attachments.map do |attachment|
            y.yield(name: attachment.inline? ? attachment.cid : attachment.filename,
                    type: attachment.mime_type,
                    content: Base64.encode64(attachment.body.decoded),
                    inline: attachment.inline?)
          end
        end
      end

      def attachments?(filter = {})
        found = mail.attachments && !mail.attachments.empty?

        if found && filter.key?(:inline)
          found &&= mail.attachments.any? { |a| a.inline? == filter[:inline] }
        end

        found
      end
    end
  end
end
