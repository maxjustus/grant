module Grant
  class ConfigParser
    
    def self.extract_config(args)
      normalize_config args
      validate_config args
      args
    end
    
    private
    
      def self.normalize_config(actions)
        actions.each_with_index { |item, index| actions[index] = item.to_sym unless item.kind_of? Symbol }
      end
    
      def self.validate_config(actions)
        raise Grant::Error.new("at least one :create, :find, :update, or :destroy action must be specified") if actions.empty?
        raise Grant::Error.new(":create, :find, :update, and :destroy are the only valid actions") unless actions.all? { |a| [:create, :find, :update, :destroy].include? a }
      end
     
  end
end