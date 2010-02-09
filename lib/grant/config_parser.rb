module Grant
  class ConfigParser
    
    def self.extract_config(args)
      hash = (args.pop if args.last.is_a?(::Hash)) || {}
      normalize_config args, hash
      validate_config args, hash
      
      [args, hash]
    end
    
    private
    
      def self.normalize_config(actions, associations)
        actions.each_with_index { |item, index| actions[index] = item.to_sym unless item.kind_of? Symbol }
        associations.each_pair { |k, v| associations[k.to_sym] = associations.delete(k) unless k.kind_of? Symbol }
      end
    
      def self.validate_config(actions, associations)
        raise Grant::Error.new "at least one :create, :find, :update, or :destroy action must be specified" if actions.empty? && associations.empty?
        raise Grant::Error.new ":create, :find, :update, and :destroy are the only valid actions" unless actions.all? { |a| [:create, :find, :update, :destroy].include? a }
        raise Grant::Error.new ":add and :remove are the only valid association specifications" unless associations.keys.all? { |k| [:add, :remove].include? k }
      end
     
  end
end