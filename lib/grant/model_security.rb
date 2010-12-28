require 'grant/config_parser'
require 'grant/user'
require 'grant/thread_status'

module Grant
  module ModelSecurity
    
    def self.included(base)
      [:create, :update, :destroy, :find].each do |action|
        callback = (action == :find ? "after_#{action}" : "before_#{action}")
        base.class_eval <<-RUBY
          def grant_#{callback}
            grant_raise_error(grant_current_user, '#{action}', self) unless grant_disabled?
          end
        RUBY
        base.send callback.to_sym, "grant_#{callback}".to_sym
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
    
    def grant_raise_error(user, action, model, association_id=nil, associated_model=nil)
      msg = ["#{action} permission",
        "not granted to #{user.class.name}:#{user.id}",
        "for resource #{model.class.name}:#{model.id}"]
      msg.insert(1, "to #{association_id}:#{associated_model.class.name} association") if association_id && associated_model

      raise Grant::Error.new(msg.join(' '))
    end
  
    module ClassMethods
      def grant(*args, &blk)
        actions, associations = Grant::ConfigParser.extract_config(args)
      
        associations.each_pair do |action, association_ids|
          Array(association_ids).each do |association_id|
            grant_callback = "grant_#{action}_#{association_id}".to_sym
            define_method(grant_callback) do |associated_model|
              grant_raise_error(grant_current_user, action, self, association_id, associated_model) unless grant_disabled? || blk.call(grant_current_user, self, associated_model)
            end
          end
        end
      
        actions.each do |action|
          grant_callback = (action.to_sym == :find ? "grant_after_find" : "grant_before_#{action}").to_sym
          define_method(grant_callback) do
            grant_raise_error(grant_current_user, action, self) unless grant_disabled? || blk.call(grant_current_user, self)
          end
        end
      end
    
      def has_and_belongs_to_many(association_id, options={}, &extension)
        add_grant_association_callback(:add, association_id, options)
        add_grant_association_callback(:remove, association_id, options)
        super
      end
    
      def has_many(association_id, options={}, &extension)
        add_grant_association_callback(:add, association_id, options)
        add_grant_association_callback(:remove, association_id, options)
        super
      end
    
      private
    
        def add_grant_association_callback(action, association_id, options)
          callback_name = "before_#{action}".to_sym
          callback = "grant_#{action}_#{association_id}".to_sym
          unless self.instance_methods.include? callback.to_s
            class_eval <<-RUBY
              def #{callback}(associated_model)
                grant_raise_error(grant_current_user, '#{action}', self, '#{association_id}', associated_model) unless grant_disabled?
              end
            RUBY
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
