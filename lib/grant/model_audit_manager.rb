module Grant
  class ModelAuditManager

    @@current_audit_symbol = :grant_current_audit

    def initialize
      @audits = {}
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
    
    def add_audit(action, options, message_proc)
      validate_action(action)
      validate_options(options)
      
      @audits[action.to_sym] = {:options => normalize_options(options),
                                :message_proc => message_proc}
    end

    def current_audit
      Thread.current[@@current_audit_symbol]
    end

    def current_audit=(audit)
      Thread.current[@@current_audit_symbol] = audit
    end

    def before(action, model)
      unless model.class.grant_disabled? || model.class.model_audit_disabled? || @audits[action].nil?
        audit = @audits[action]
        user = Grant::User.current_user
        self.current_audit = Audit.new(:auditable_id => model.id,
                           :auditable_type => model.class.to_s,
                           :user_id => user.id,
                           :user_type => user.class.to_s,
                           :action => action.to_s,
                           :changes => prepare_changes(model.changes, audit[:options]),
                           :success => false)
        self.current_audit.message = model.class.without_grant { audit[:message_proc].call(model, user) } if audit[:message_proc]
      end
    end

    def after(action, model)
      unless model.class.grant_disabled? || model.class.model_audit_disabled? || @audits[action].nil?
        self.current_audit.auditable_id = model.id
        self.current_audit.auditable_version = model.version if model.respond_to? :version
        self.current_audit.success = true
        self.current_audit.save
        self.current_audit = nil
      end
    end

    def after_find(model)
      unless model.class.grant_disabled? || model.class.model_audit_disabled? || @audits[:find].nil?
        user = Grant::User.current_user
        audit = @audits[:find]
        current_audit = Audit.new(:auditable_id => model.id,
                                  :auditable_type => model.class.to_s,
                                  :user_id => user.id,
                                  :user_type => user.class.to_s,
                                  :action => 'find',
                                  :success => true)
        current_audit.auditable_version = model.version if model.respond_to? :version
        current_audit.message = model.class.without_grant { audit[:message_proc].call(model, user) } if audit[:message_proc]
        current_audit.save
      end
    end

    def before_create(model); before(:create, model) end
    def after_create(model); after(:create, model) end
    def before_update(model); before(:update, model) end
    def after_update(model); after(:update, model) end
    def before_destroy(model); before(:destroy, model) end
    def after_destroy(model); after(:destroy, model) end
    
    
    private 
    
      def validate_action(action)
        valid_actions = [:find, :create, :update, :destroy]
        raise AuditError.new("#{action} is an invalid audit action. Valid actions include #{valid_actions.join(', ')}") unless valid_actions.include?(action.to_sym)
      end
    
      def validate_options(options)
        raise AuditError.new('only one of :except or :only may be specified') if options && options[:except] && options[:only]
      end

  end
end
