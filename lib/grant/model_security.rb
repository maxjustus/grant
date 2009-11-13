module Grant
  module ModelSecurity
    
    def self.included(base)
      base.instance_eval do
        alias original_has_and_belongs_to_many has_and_belongs_to_many
        alias original_has_many has_many
        
        write_inheritable_attribute :model_security_manager, Grant::ModelSecurityManager.new
        class_inheritable_reader :model_security_manager
        
        before_create model_security_manager
        before_update model_security_manager
        before_destroy model_security_manager
        after_find model_security_manager
      end
      
      base.extend Grant::Base::ClassMethods
      base.extend ClassMethods
    end
    
    # ActiveRecord won't call the after_find handler unless it see's a specific after_find method defined
    def after_find; end
    
    
    module ClassMethods

      def model_security_disabled?
        @model_security_disabled = Grant::ThreadLocal.new(false) if @model_security_disabled.nil?
        @model_security_disabled.get
      end
      
      def without_model_security
        previously_disabled = model_security_disabled?
        @model_security_disabled.set true

        begin
          result = yield if block_given?
        ensure
          @model_security_disabled.set previously_disabled
        end

        result
      end
      
      def grant(*args, &blk)
        model_security_manager.add_callback(blk, args)
      end
      
      def has_and_belongs_to_many(association_id, options={}, &extension)
        add_association_callback(:before_add, association_id, options)
        add_association_callback(:before_remove, association_id, options)
        original_has_and_belongs_to_many(association_id, options, &extension)
      end
      
      def has_many(association_id, options={}, &extension)
        add_association_callback(:before_add, association_id, options)
        add_association_callback(:before_remove, association_id, options)
        original_has_many(association_id, options, &extension)
      end
      

      private
      
        def add_association_callback(callback_name, association_id, options)
          callback = Proc.new do |model, associated_model| 
            model_security_manager.send("#{callback_name}_association".to_sym, association_id, model, associated_model)
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
