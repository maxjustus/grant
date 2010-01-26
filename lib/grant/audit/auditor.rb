require 'grant'
require 'grant/config_parser'
require 'grant/user'
require 'grant/audit/event'

module Grant
  module Audit
    class Auditor
      include Grant::ConfigParser
    
      def initialize
        @events = []
      end
    
      def audit(args, &blk)
        actions, associations, options = extract_config(args)
        actions.each { |action| @events << Grant::Audit::Event.new(action.to_sym, options, &blk) }
        associations.each_pair do |action, attributes|
          Array(attributes).each { |attr| @events << Grant::Audit::Event.new(action.to_sym, options, attr, &blk) }
        end
      end
    
      def before_create(model)
        audit(:create, model)
      end
    
      def before_update(model)
        audit(:update, model)
      end
    
      def before_destroy(model)
        audit(:destroy, model)
      end
    
      def after_find(model)
        audit(:find, model)
      end
    
      def before_add_association(association_id, model, associated_model)
        audit_association(:add, model, association_id, associated_model)
      end
    
      def before_remove_association(association_id, model, associated_model)
        audit_association(:remove, model, association_id, associated_model)
      end
    
      private
        def audit(action, model)
          @events.each { |event| event.audit(action, model) }
        end
      
        def audit_association(action, model, association_id, associated_model)
          @events.each { |event| event.audit(action, model, association_id, associated_model) }
        end
      
        def user
          Grant::User.current_user
        end
    
    end
  end
end