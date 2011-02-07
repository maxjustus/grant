require 'grant/user'
require 'grant/thread_status'
require 'grant/model_security'

module Grant
  module ModelAttributeSecurity
    include ModelSecurityMethods

    def granted_attributes(*attrs_and_args)
      if attrs_and_args.last.instance_of?(Hash)
        args = attrs_and_args.pop
        args = Hash[args.collect {|option,value| [option.to_sym, value]}]
      else
        args = {:granted => true}
      end

      arg_attrs = attrs_and_args.collect {|attr| attr.to_sym}

      attrs = granted_attribute_hash.select {|attr,granted| granted == args[:granted]}.collect {|attr,granted| attr}

      if arg_attrs.length > 0
        attrs.select {|attr| arg_attrs.include? attr}
      else
        attrs
      end
    end

    def granted_attributes?(*attrs)
      granted_attributes(*attrs, :granted => false).length == 0
    end

    private

    def granted_attribute_hash
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
            if blk.call(grant_current_user, self)
              grant_attributes[attr] = true
            else
              grant_attributes[attr] = false
            end
          end
        end
      end

      grant_attributes
    end

    def grant_before_save
      grant_raise_error(grant_current_user, 'save', self) unless grant_disabled?
    end
  
    def self.included(base)
      base.class_eval do
        @granted_permissions = []
        class << self; attr_accessor :granted_permissions; end
      end

      base.before_save :grant_before_save
    
      base.extend ClassMethods
    end

    module ClassMethods
      def grant_attributes(*args, &blk)
        attributes = args.collect {|attr| attr}
        @granted_permissions << [attributes, blk]

        define_method(:grant_before_save) do
          if self.changed.length > 0
            ungranted_changed = granted_attributes(*self.changed, :granted => false)
            unless (ungranted_changed).length == 0
              grant_raise_error(grant_current_user, ungranted_changed.join(', '), self)
            end
          end
        end
      end
    end
    
  end
  
end
