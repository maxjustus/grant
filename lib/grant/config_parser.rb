module Grant
  module ConfigParser
    
    def extract_config(args)
      hash = (args.delete_at(args.size - 1) if args.last.kind_of?(Hash)) || {}
      options = {}
      
      hash.keys.each do |key|
        if [:only, :except].include? key.to_sym
          options[key] = hash[key]
          hash.delete key
        end
      end

      normalize_config args, hash, options
      validate_config args, hash, options
      
      [args, hash, options]
    end
    
    private
    
      def normalize_config(actions, associations, options)
        actions.each_with_index { |item, index| actions[index] = item.to_sym unless item.kind_of? Symbol }
        associations.each_pair { |k, v| associations[k.to_sym] = associations.delete(k) unless k.kind_of? Symbol }
        options.each_pair { |k, v| options[k.to_sym] = options.delete(k) unless k.kind_of? Symbol }
      end
    
      def validate_config(actions, associations, options)
        raise Grant::Error.new "at least one :create, :find, :update, or :destroy action must be specified" if actions.empty? && associations.empty?
        raise Grant::Error.new ":create, :find, :update, and :destroy are the only valid actions" unless actions.all? { |a| [:create, :find, :update, :destroy].include? a }
        raise Grant::Error.new ":add and :remove are the only valid association specifications" unless associations.keys.all? { |k| [:add, :remove].include? k }
        raise Grant::Error.new "only one of :except and :only can be specified" if options.size > 1
      end
     
  end
end