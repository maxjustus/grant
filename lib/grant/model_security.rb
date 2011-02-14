require 'grant/config_parser'
require 'grant/user'
require 'grant/thread_status'

module Grant
  module ModelSecurity
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

    def granted(*args)
      if args.last.instance_of?(Hash)
        options = args.pop
        options = Hash[options.collect {|option,value| [option.to_sym, value]}]
      else
        options = {:granted => true}
      end

      arg_attrs_and_actions = Grant::ConfigParser.extract_config(args, self.class)

      granted_attrs_and_actions = {:actions => [], :attributes => []}

      granted_attrs_and_actions.each_key do |k|
        granted = eval("granted_#{k}").select {|a,granted| granted == options[:granted]}.collect {|a,granted| a}

        if arg_attrs_and_actions[k].length > 0
          granted_attrs_and_actions[k] = arg_attrs_and_actions[k].select{|a| granted.include? a}
        elsif arg_attrs_and_actions.reject{|a| a == k}.shift[1].length == 0
          granted_attrs_and_actions[k] = granted.sort {|a, a2| a.to_s <=> a2.to_s}
        end
      end

      granted_attrs_and_actions
    end

    def granted?(*args)
      granted(*args.push(:granted => false)).all? {|k, v| v.length == 0}
    end

    private

    def granted_actions
      grant_actions = {:create => false, :update => false, :destroy => false, :find => false}
      
      grant_actions.each do |action, granted|
        callback = (action == :find ? "after_#{action}" : "before_#{action}")
        begin
          eval "grant_#{callback}"
          grant_actions[action] = true
        rescue
          grant_actions[action] = false
        end
      end

      grant_actions
    end

    def granted_attributes
      grant_attributes = Hash[*self.attribute_names.collect {|attr| [attr.to_sym, false]}.flatten]

      if grant_disabled?
        grant_attributes.each_key do |attr|
          grant_attributes[attr] = true
        end
      else
        self.class.granted_permissions.each do |attrs_and_blk|
          attrs = attrs_and_blk[0]
          blk = attrs_and_blk[1]
          attrs.each do |attr|
            grant_attributes[attr] = !!blk.call(grant_current_user, self)
          end
        end
      end

      grant_attributes
    end
    
    def self.included(base)
      base.class_eval do
        @granted_permissions = []
        class << self; attr_accessor :granted_permissions; end
      end

      [:create, :update, :destroy, :find, :save].each do |action|
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
        args = Grant::ConfigParser.extract_config(args, self)

        args[:actions].each do |action|
          grant_callback = (action.to_sym == :find ? "grant_after_find" : "grant_before_#{action}").to_sym
          define_method(grant_callback) do
            grant_raise_error(grant_current_user, action, self) unless grant_disabled? || blk.call(grant_current_user, self)
          end
        end

        if args[:attributes]
          @granted_permissions << [args[:attributes], blk]

          define_method(:grant_before_save) do
            if self.changed.length > 0 && !grant_disabled?
              ungranted_changed = granted_attributes(*self.changed.push(:granted => false))
              unless (ungranted_changed).length == 0
                grant_raise_error(grant_current_user, ungranted_changed.join(', '), self)
              end
            end
          end
        end
      end
    end
    
  end
  
end
