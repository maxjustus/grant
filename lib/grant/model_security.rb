require 'grant/config_parser'
require 'grant/user'
require 'grant/thread_status'

module Grant
  module ModelSecurityMethods
  
    def grant_current_user
      Grant::User.current_user
    end
  
    def grant_disabled?
      Grant::ThreadStatus.disabled? || @grant_disabled
    end
    
    def grant_raise_error(user, action, model, association_id=nil)
      msg = ["#{action} permission",
        "not granted to #{user.class.name}:#{user.id}",
        "for resource #{model.class.name}:#{model.id}"]

      raise Grant::Error.new(msg.join(' '))
    end
  end

  module ModelSecurity
    include ModelSecurityMethods
    
    def self.included(base)
      [:create, :update, :destroy, :find].each do |action|
        callback = (action == :find ? "after_#{action}" : "before_#{action}")
        base.class_eval <<-RUBY
          def grant_#{callback}
            grant_raise_error(grant_current_user, '#{action}', self) unless grant_disabled?
          end
        RUBY
        base.send(callback.to_sym, "grant_#{callback}".to_sym)
      end
    
      base.extend ClassMethods
    end
  
    # ActiveRecord won't call the after_find handler unless it see's a specific after_find method defined
    def after_find; end
  
    module ClassMethods
      def grant(*args, &blk)
        actions = Grant::ConfigParser.extract_config(args)
        actions.each do |action|
          grant_callback = (action.to_sym == :find ? "grant_after_find" : "grant_before_#{action}").to_sym
          define_method(grant_callback) do
            grant_raise_error(grant_current_user, action, self) unless grant_disabled? || blk.call(grant_current_user, self)
          end
        end
      end
    end
    
  end
  
end
