require 'grant'
require 'grant/config_parser'
require 'grant/user'
require 'grant/constraint'

module Grant
  class Enforcer
    include Grant::ConfigParser
  
    def initialize
      @constraints = []
    end
  
    def enforce(args, &blk)
      actions, associations, options = extract_config(args)
      actions.each { |action| @constraints << Grant::Constraint.new(action.to_sym, &blk) }
      associations.each_pair do |action, attributes|
        Array(attributes).each { |attr| @constraints << Grant::Constraint.new(action.to_sym, attr, &blk) }
      end
    end
  
    def before_create(model)
      check(:create, model)
    end
  
    def before_update(model)
      check(:update, model)
    end
  
    def before_destroy(model)
      check(:destroy, model)
    end
  
    def after_find(model)
      check(:find, model)
    end
  
    def before_add_association(association_id, model, associated_model)
      check_association(:add, model, association_id, associated_model)
    end
  
    def before_remove_association(association_id, model, associated_model)
      check_association(:remove, model, association_id, associated_model)
    end
  
    private
      def check(action, model)
        unless @constraints.empty? || @constraints.any? { |constraint| constraint.permitted? action, model }
          raise Grant::Error.new("#{action} permission not granted to #{user.class.name}:#{user.id} for resource #{model.class.name}:#{model.id}")
        end
      end
    
      def check_association(action, model, association_id, associated_model)
        unless @constraints.empty? || @constraints.any? { |constraint| constraint.permitted? action, model, association_id, associated_model }
          raise Grant::Error.new("#{action} permission to #{association_id}:#{associated_model.class.name} association not granted to #{user.class.name}:#{user.id} for resource #{model.class.name}:#{model.id}")
        end
      end
    
      def user
        Grant::User.current_user
      end
  
  end
end