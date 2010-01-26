require 'grant/audit/auditor'

module Grant
  module Audit
    def self.included(base)
      base.instance_eval do
        alias grant_audit_has_and_belongs_to_many has_and_belongs_to_many
        alias grant_audit_has_many has_many
      end
      
      base.extend ClassMethods
    end
    
    # ActiveRecord won't call the after_find handler unless it see's a specific after_find method defined
    def after_find; end
    
    module ClassMethods
      def audit(*args, &blk)
        actions, associations, options = extract_config(args)
        actions.each do |action| 
          event = Grant::Audit::Event.new(action.to_sym, options, &blk)
          self.send "before_#{action}".to_sym, event unless action.to_sym == :find
          self.send "after_#{action}".to_sym, event
        end
        associations.each_pair do |action, attributes|
          Array(attributes).each do |attr| 
            @events << Grant::Audit::Event.new(action.to_sym, options, attr, &blk) 
          end
        end
      end
      
      def has_and_belongs_to_many(association_id, options={}, &extension)
        add_association_callback(:before_add, association_id, options)
        add_association_callback(:before_remove, association_id, options)
        grant_audit_has_and_belongs_to_many(association_id, options, &extension)
      end
      
      def has_many(association_id, options={}, &extension)
        add_association_callback(:before_add, association_id, options)
        add_association_callback(:before_remove, association_id, options)
        grant_audit_has_many(association_id, options, &extension)
      end
      
      private
      
        def add_association_callback(callback_name, association_id, options)
          callback = Proc.new do |model, associated_model| 
            auditor.send("#{callback_name}_association".to_sym, association_id, model, associated_model)
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