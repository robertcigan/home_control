module AttributeOption
  extend ActiveSupport::Concern
  
  class_methods do
    def attribute_options(attribute, options)
      options.map!(&:to_s)
      attribute_module = Module.new do
        options.each do |option|
          const_set(option.upcase, option)
        end
      end

      const_set(attribute.to_s.classify, attribute_module)

      define_singleton_method attribute.to_s.pluralize do
        options
      end

      define_singleton_method "#{attribute.to_s.pluralize}_to_collection" do
        Hash[options.map{ |option| [I18n.t("activerecord.attribute_options.#{model_name.singular}.#{attribute}.#{option}"), option] }]
      end

      define_method "#{attribute.to_s}_to_human" do
        value = send(attribute)
        I18n.t("activerecord.attribute_options.#{model_name.singular}.#{attribute}.#{value}") if value.present?
      end

      options.each do |option|
        scope "#{attribute.to_s}_#{option.to_s}".to_sym, -> { where(attribute.to_s => option.to_s) }

        define_method "#{attribute.to_s}_#{option.to_s}?" do
          send(attribute) == option
        end
      end
    end
  end
end
