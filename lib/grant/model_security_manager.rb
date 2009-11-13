module Grant
  class ModelSecurityManager
    def initialize()
      @callbacks = {:create => [], :update => [], :destroy => [], :find => [], :add => {}, :remove => {}}
    end

    def add_callback(proc, actions)
      actions = [actions] unless actions.kind_of? Array
      validate_proc(proc)
      validate_actions(actions)
      
      actions.each do |type|
        if type.kind_of? Hash
          type.each do |association_type, association|
            if association.kind_of? Array
              association.each do |association_id|
                @callbacks[association_type][association_id] ||= []
                @callbacks[association_type][association_id] << proc
              end
            else
              @callbacks[association_type][association] ||= []
              @callbacks[association_type][association] << proc
            end
          end
        else
          @callbacks[type] << proc
        end
      end
    end
    
    def before_create(model)
      apply_security(model, :create)
    end
    
    def before_update(model)
      apply_security(model, :update)
    end
    
    def before_destroy(model)
      apply_security(model, :destroy)
    end
    
    def after_find(model)
      apply_security(model, :find)
    end
    
    def before_add_association(association_id, model, associated_model)
      apply_association_security(model, :add, association_id, associated_model)
    end
    
    def before_remove_association(association_id, model, associated_model)
      apply_association_security(model, :remove, association_id, associated_model)
    end

    private
    
      def apply_security(model, type)
        unless model.class.grant_disabled? || model.class.model_security_disabled?
          type_callbacks = @callbacks[type]
          permission_not_granted(type, model) unless !type_callbacks.empty? &&
            type_callbacks.all? { |proc| model.class.without_grant { proc.call(Grant::User.current_user, model) } }
        end
      end
    
      def apply_association_security(model, type, association_id, associated_model)
        unless model.class.grant_disabled? || model.class.model_security_disabled?
          type_callbacks = @callbacks[type][association_id]
          association_permission_not_granted(type, model, associated_model) unless !type_callbacks.nil? && !type_callbacks.empty? &&
            type_callbacks.all? { |proc| model.class.without_grant { proc.call(Grant::User.current_user, model, associated_model) } }
        end
      end
    
      def permission_not_granted(type, model)
        user = Grant::User.current_user
        raise ModelSecurityError.new("#{type} permission not granted to #{user.class.name}:#{user.id} for resource #{model.class.name}:#{model.id}")
      end
    
      def association_permission_not_granted(type, model, associated_model)
        user = Grant::User.current_user
        raise ModelSecurityError.new("#{type} permission to #{associated_model.class.name} association not granted to #{user.class.name}:#{user.id} for resource #{model.class.name}:#{model.id}")
      end
      
      def validate_proc(proc)
        raise Grant::ModelSecurityError.new('A block must be given for calls to "grant"') if proc.nil?
      end

      def validate_actions(actions)
        valid_actions = [:find, :create, :update, :destroy, :add, :remove]
      
        actions_to_check = actions.kind_of?(Array) ? actions.dup : [actions]
        association_actions = actions_to_check.delete_at(actions_to_check.length - 1).keys if actions_to_check.last.is_a? Hash
        actions_to_check = actions_to_check.concat(association_actions) unless association_actions.nil?
      
        actions_to_check.each do |action|
          raise ModelSecurityError.new("#{action} is an invalid model security action. Valid actions include #{valid_actions.join(', ')}") unless valid_actions.include?(action.to_sym)
        end
      end
      
  end
  
  class ModelSecurityError < StandardError; end
end