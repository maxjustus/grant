module Grant
  module ModelAudit

    def self.included(base)
      base.instance_eval do
        write_inheritable_attribute :model_audit_manager, Grant::ModelAuditManager.new
        class_inheritable_reader :model_audit_manager
      end
      
      base.extend Grant::Base::ClassMethods
      base.extend ClassMethods
    end

    module ClassMethods
      def model_audit_disabled?
        @model_audit_disabled = Grant::ThreadLocal.new(false) if @model_audit_disabled.nil?
        @model_audit_disabled.get
      end
      
      def without_model_audit
        previously_disabled = model_audit_disabled?
        @model_audit_disabled.set true

        begin
          result = yield if block_given?
        ensure
          @model_audit_disabled.set previously_disabled
        end

        result
      end

      def audit(*args, &blk)
        options = args.delete_at(args.length - 1) if args.last.is_a? Hash
        
        args.each do |action|
          model_audit_manager.add_audit action, options, blk
          self.send "before_#{action}".to_sym, model_audit_manager unless action.to_sym == :find
          self.send "after_#{action}".to_sym, model_audit_manager
          
          # ActiveRecord won't call the after_find handler unless it see's a specific after_find method defined
          define_method(:after_find) { } if action.to_sym == :find
        end
      end
      
    end
    
    class AuditError < StandardError; end
    
  end
end