require 'grant/user'

module Grant
  class Constraint
  
    def initialize(action, attribute=nil, &block)
      raise ArgumentError.new("An action is required as the first argument.") unless action
      raise ArgumentError.new("A block is required as the last argument.") unless block
      
      @action = action.to_sym
      @attribute = attribute.to_sym if attribute
      @block = block
    end

    def permitted?(action, model, association=nil, associated_model=nil)
      if association
        @block.call(user, model, associated_model) if action.to_sym == @action && association.to_sym == @attribute
      else
        @block.call(user, model) if action.to_sym == @action
      end
    end    
  
    private
      def user
        Grant::User.current_user
      end
    
  end
end