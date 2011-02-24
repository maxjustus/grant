module Grant
  class ConfigParser
    
    def self.extract_config(args, resource)
      args = normalize_config args, resource
      validate_config args, resource
      args
    end
    
    private
    
      def self.normalize_config(args, resource)
        normalized_args = {:actions => [], :attributes => []}
        args.each_with_index do |item, index|
          if item.kind_of? Hash
            attrs = item[:attributes] ? item[:attributes] : item['attributes']

            if !attrs.kind_of?(Array) && attrs.to_sym == :all
              if resource.table_exists?
                attrs = resource.column_names.collect {|c| c.to_sym}
              else
                attrs = []
              end
            end

            normalized_args[:attributes] << attrs
          else
            item = item.to_sym

            if [:create, :find, :update, :destroy].include?(item)
              normalized_args[:actions] << item
            else
              normalized_args[:attributes] << item
            end
          end
        end

        normalized_args[:attributes] = normalized_args[:attributes].flatten.uniq
        normalized_args
      end
    
      def self.validate_config(args, resource)
        if args[:actions] == nil && args[:attributes] == nil
          valid_args = [:create, :find, :update, :destroy]
          resource.column_names.each do |attr|
            valid_args << attr
          end

          raise Grant::Error.new("at least one of " + valid_args.join(', ') + " must be specified")
        end

        raise Grant::Error.new(":create, :find, :update, and :destroy are the only valid actions") unless args[:actions].all? { |a| [:create, :find, :update, :destroy].include? a }

        if resource.table_exists?
          attribute_names = resource.column_names
          raise Grant::Error.new(attribute_names.join(', ') + " are the only valid attributes") unless args[:attributes].all? { |a| attribute_names.include? a.to_s }
        end
      end
     
  end
end
