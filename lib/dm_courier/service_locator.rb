require "dm_courier/services/mandrill"
require "dm_courier/services/sparkpost"

module DMCourier
  module ServiceLocator
    def service
      @service ||= begin
                     raise DMCourier::InvalidService unless @service_name

                     constantize(@service_name)
                   end
    rescue NameError => e
      raise DMCourier::InvalidService, e
    end

    def constantize(service_name)
      camel_cased_word = "DMCourier::Services::#{service_name.to_s.tr('_', ' ').split.map(&:capitalize).join('')}"
      names = camel_cased_word.split("::")

      Object.const_get(camel_cased_word) if names.empty?

      names.shift if names.size > 1 && names.first.empty?

      names.inject(Object) do |constant, name|
        if constant == Object
          constant.const_get(name)
        else
          candidate = constant.const_get(name)
          next candidate if constant.const_defined?(name, false)
          next candidate unless Object.const_defined?(name)

          constant = constant.ancestors.inject do |const, ancestor|
            break const    if ancestor == Object
            break ancestor if ancestor.const_defined?(name, false)
            const
          end

          constant.const_get(name, false)
        end
      end
    end
  end
end
