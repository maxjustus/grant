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
      user_name = user != nil ? "#{user.class.name}:#{user.id}" : "unlogged in user"
      model_name = model.id ? "#{model.class.name}:#{model.id}" : "new #{model.class.name}"
      msg = ["#{action} permission",
        "not granted to #{user_name}",
        "for resource #{model_name}"]

      raise Grant::Error.new(msg.join(' '))
    end

    def granted(*args)
      if args.last.instance_of?(Hash)
        options = args.pop
        options = Hash[options.collect {|option,value| [option.to_sym, value]}]
      else
        options = {:granted => true}
      end

      args = Grant::ConfigParser.extract_config(args, self.class)
      granted_attrs_and_actions = {:actions => [], :attributes => []}
      no_arguments = args.all? {|k,v| v.length == 0}

      args.each do |arg_type,arg_list|
        #if arguments exist for the current key, or no arguments exist
        if arg_list.length > 0 || no_arguments
          #get all permissions and filter by options[:granted]
          granted = eval("granted_#{arg_type}(args[arg_type])").select {|a,granted| granted == options[:granted]}.collect {|a,granted| a}
          granted.sort! {|v1,v2| v1 <=> v2} if no_arguments

          granted_attrs_and_actions[arg_type] = granted
        end
      end

      granted_attrs_and_actions
    end

    def granted?(*args)
      granted(*args.push(:granted => false)).all? {|k, v| v.length == 0}
    end

    private

    def granted_actions(check_actions)
      check_actions = check_actions.length == 0 ? [:create, :update, :destroy, :find] : check_actions

      #make a hash of action names with their grant status
      grant_actions = Hash[*check_actions.collect {|action| [action.to_sym, false]}.flatten]
      
      grant_actions.each_key do |action|
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

    def granted_attributes(check_attributes)
      check_attributes = check_attributes.length == 0 ? self.attribute_names : check_attributes

      #make a hash of attribute names with their grant status
      grant_attributes = Hash[*check_attributes.collect {|attr| [attr.to_sym, false]}.flatten]

      if grant_disabled?
        grant_attributes.each_key do |attr|
          grant_attributes[attr] = true
        end
      else
        self.class.granted_permissions.each do |attrs_and_blk|
          attrs = attrs_and_blk[0].select {|a| grant_attributes.has_key?(a)}
          if attrs.length > 0
            blk = attrs_and_blk[1]
            blk_result = !!blk.call(grant_current_user, self)
            attrs.each do |attr|
              grant_attributes[attr] = blk_result
            end
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
              ungranted_changed = granted(*self.changed.push(:granted => false))[:attributes]
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
