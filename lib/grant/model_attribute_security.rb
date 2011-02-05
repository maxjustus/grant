require 'grant/config_parser'
require 'grant/user'
require 'grant/thread_status'
require 'grant/model_security'

module Grant
  module ModelAttributeSecurity
    include ModelSecurityMethods

    def self.included(base)
      base.class_eval do
        @granted_permissions = []
        class << self; attr_accessor :granted_permissions; end

        def grant_before_save
          grant_raise_error(grant_current_user, 'save', self) unless grant_disabled?
        end
      end

      base.before_save :grant_before_save
    
      base.extend ClassMethods
    end
  
    module ClassMethods
      def grant_attributes(*args, &blk)
        attributes = args.collect {|attr| attr.to_s}
        @granted_permissions << [attributes, blk]

        define_method(:grant_before_save) do
          granted = false
          ungranted_attributes = Hash[*self.changed.collect {|c| [c, nil]}.flatten]

          self.class.granted_permissions.each do |attrs_and_blk|
            attrs = attrs_and_blk[0]
            blk = attrs_and_blk[1]
            attrs.each do |attr|
              if grant_disabled?
                granted = true
              elsif self.changed.include?(attr)
                if blk.call(grant_current_user, self)
                  granted = true
                else
                  granted = false
                end
              end

              if granted
                ungranted_attributes.delete(attr)
              end
            end
          end

          unless granted && ungranted_attributes.length == 0
            grant_raise_error(grant_current_user, ungranted_attributes.to_a.flatten.compact.join(', '), self)
          end
        end
      end
    end
    
  end
  
end
