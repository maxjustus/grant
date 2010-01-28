require 'grant/security/enforcer'

module Grant
  module Security
    def self.included(base)
      base.instance_eval do
        alias grant_security_has_and_belongs_to_many has_and_belongs_to_many
        alias grant_security_has_many has_many
        
        write_inheritable_attribute :enforcer, Grant::Enforcer.new
        class_inheritable_reader :enforcer
        
        before_create enforcer
        before_update enforcer
        before_destroy enforcer
        after_find enforcer
      end
      
      base.extend ClassMethods
    end
    
    # ActiveRecord won't call the after_find handler unless it see's a specific after_find method defined
    def after_find; end
    
    module ClassMethods
      def grant(*args, &blk)
        enforcer.enforce(args, &blk)
      end
      
      def has_and_belongs_to_many(association_id, options={}, &extension)
        add_association_callback(:before_add, association_id, options)
        add_association_callback(:before_remove, association_id, options)
        grant_security_has_and_belongs_to_many(association_id, options, &extension)
      end
      
      def has_many(association_id, options={}, &extension)
        add_association_callback(:before_add, association_id, options)
        add_association_callback(:before_remove, association_id, options)
        grant_security_has_many(association_id, options, &extension)
      end
      
      private
      
        def add_association_callback(callback_name, association_id, options)
          callback = Proc.new do |model, associated_model| 
            enforcer.send("#{callback_name}_association".to_sym, association_id, model, associated_model)
          end
        
          if options.has_key? callback_name
            if options[callback_name].kind_of? Array
              options[callback_name].insert(0, callback)
            else
              options[callback_name] = [callback, options[callback_name]]
            end
          else
            options[callback_name] = callback
          end
        end
      
    end
  end
end