module Grant
  module Security
    
    def self.included(base)
      base.instance_eval do
        alias grant_security_has_and_belongs_to_many has_and_belongs_to_many
        alias grant_security_has_many has_many
      
        [:create, :update, :destroy, :find].each do |action|
          callback = (action == :find ? "after_#{action}".to_sym : "before_#{action}".to_sym)
          grant_callback = "grant_#{callback}".to_sym
          define_method(grant_callback) do
            grant_raise_error(grant_current_user, action, self) unless grant_disabled?
          end
          send callback, grant_callback
        end
      end
    
      base.extend ClassMethods
    end
  
    # ActiveRecord won't call the after_find handler unless it see's a specific after_find method defined
    def after_find; end
  
    def grant_current_user
      Grant::User.current_user
    end
  
    def grant_disabled?
      Grant::ThreadStatus.disabled? || @grant_disabled
    end
    
    def grant_raise_error(user, action, model, associated_model=nil)
      msg = ["#{action} permission",
        "not granted to #{user.class.name}:#{user.id}",
        "for resource #{model.class.name}:#{model.id}"]
      msg.insert(1, "to #{association_id}:#{associated_model.class.name} association") if associated_model

      raise Grant::Error.new(msg.join(' '))
    end
  
    module ClassMethods
      def grant(*args, &blk)
        actions, associations = Grant::ConfigParser.extract_config(args)
      
        associations.each_pair do |action, association_ids|
          Array(association_ids).each do |association_id|
            grant_callback = "grant_#{action}_#{association_id}".to_sym
            define_method(grant_callback) do |associated_model|
              grant_raise_error(grant_current_user, action, self, associated_model) unless grant_disabled? || blk.call(grant_current_user, self, associated_model)
            end
          end
        end
      
        actions.each do |action|
          grant_callback = (action.to_sym == :find ? "grant_after_find".to_sym : "grant_before_#{action}".to_sym)
          define_method(grant_callback) do
            grant_raise_error(grant_current_user, action, self) unless grant_disabled? || blk.call(grant_current_user, self)
          end
        end
      end
    
      def has_and_belongs_to_many(association_id, options={}, &extension)
        add_association_callback(:add, association_id, options)
        add_association_callback(:remove, association_id, options)
        grant_security_has_and_belongs_to_many(association_id, options, &extension)
      end
    
      def has_many(association_id, options={}, &extension)
        add_association_callback(:add, association_id, options)
        add_association_callback(:remove, association_id, options)
        grant_security_has_many(association_id, options, &extension)
      end
    
      private
    
        def add_association_callback(action, association_id, options)
          callback_name = "before_#{action}".to_sym
          callback = "grant_#{action}_#{association_id}".to_sym
          define_method(callback) do |associated_model|
            grant_raise_error(grant_current_user, action, self, associated_model) unless grant_disabled?
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