require 'grant/user'

module Grant
  module Audit
    class Event
      
      @@current_audit_symbol = :grant_current_audit
    
      def initialize(action, options, attribute=nil, &block=nil)
        raise ArgumentError.new("An action is required as the first argument.") unless action
        
        @action = action.to_sym
        @options = normalize_options(options)
        @attribute = attribute.to_sym if attribute
        @block = block
      end
      
      def before_create(model); before(:create, model) end
      def after_create(model); after(:create, model) end
      def before_update(model); before(:update, model) end
      def after_update(model); after(:update, model) end
      def before_destroy(model); before(:destroy, model) end
      def after_destroy(model); after(:destroy, model) end

      private
        def current_audit
          Thread.current[@@current_audit_symbol]
        end

        def current_audit=(audit)
          Thread.current[@@current_audit_symbol] = audit
        end
      
        def normalize_options(options)
          return {:except => [], :only => []} if options.nil?
          options[:except] = options[:except] || []
          options[:only] = options[:only] || []
          options[:except] = ([] << options[:except]).flatten.map(&:to_s)
          options[:only] = ([] << options[:only]).flatten.map(&:to_s)
          options
        end
        
        def prepare_changes(changes, options)
          chg = changes.dup
          chg = chg.delete_if {|key, value| options[:except].include? key} unless options[:except].empty?
          chg = chg.delete_if {|key, value| !options[:only].include? key} unless options[:only].empty?
          chg.empty? ? nil : chg
        end
        
        def before(action, model)
          self.current_audit = Audit.new(:auditable_id => model.id,
                             :auditable_type => model.class.to_s,
                             :user_id => user.id,
                             :user_type => user.class.to_s,
                             :action => action.to_s,
                             :changes => prepare_changes(model.changes, @options),
                             :success => false)
          self.current_audit.message = @block.call(model, user) } if @block
        end

        def after(action, model)
          self.current_audit.auditable_id = model.id
          self.current_audit.auditable_version = model.version if model.respond_to? :version
          self.current_audit.success = true
          self.current_audit.save
          self.current_audit = nil
        end

        def after_find(model)
          current_audit = Audit.new(:auditable_id => model.id,
                                    :auditable_type => model.class.to_s,
                                    :user_id => user.id,
                                    :user_type => user.class.to_s,
                                    :action => 'find',
                                    :success => true)
          current_audit.auditable_version = model.version if model.respond_to? :version
          self.current_audit.message = @block.call(model, user) } if @block
          current_audit.save
        end
      
        def user
          Grant::User.current_user
        end
      
    end
  end
end