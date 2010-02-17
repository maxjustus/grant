require 'grant'

describe Grant::ModelSecurity do
  
  before(:each) do
    Grant::User.current_user = (Class.new do
      def id; 1 end
    end).new
  end
  
  describe 'module include' do
    it 'should establish failing ActiveRecord callbacks for before_create, before_update, before_destroy, and after_find when included' do
      verify_standard_callbacks(new_model_class.new)
    end
    
    it 'should establish failing ActiveRecord callbacks for any has_many or has_and_belongs_to_many associations' do
      c = new_model_class
      c.instance_eval do
        has_many :users
        has_and_belongs_to_many :groups
      end
      instance = c.new
      lambda { instance.grant_add_users(new_model_class) }.should raise_error(Grant::Error)
      lambda { instance.grant_remove_users(new_model_class) }.should raise_error(Grant::Error)
      lambda { instance.grant_add_groups(new_model_class) }.should raise_error(Grant::Error)
      lambda { instance.grant_remove_groups(new_model_class) }.should raise_error(Grant::Error)
    end
  end
  
  describe '#grant' do
    it 'should allow after_find callback to succeed when granted' do
      c = new_model_class.instance_eval { grant(:find); self }
      verify_standard_callbacks(c.new, :find)
    end
    
    it 'should allow before_create callback to succeed when granted' do
      c = new_model_class.instance_eval { grant(:create); self }
      verify_standard_callbacks(c.new, :create)
    end
    
    it 'should allow before_update callback to succeed when granted' do
      c = new_model_class.instance_eval { grant(:update); self }
      verify_standard_callbacks(c.new, :update)
    end
    
    it 'should allow before_destroy callback to succeed when granted' do
      c = new_model_class.instance_eval { grant(:destroy); self }
      verify_standard_callbacks(c.new, :destroy)
    end
    
    it 'should allow multiple callbacks to be specified with one grant statment' do
      c = new_model_class.instance_eval { grant(:create, :update); self }
      verify_standard_callbacks(c.new, :create, :update)
      
      c = new_model_class.instance_eval { grant(:create, :update, :destroy); self }
      verify_standard_callbacks(c.new, :create, :update, :destroy)
      
      c = new_model_class.instance_eval { grant(:create, :update, :destroy, :find); self }
      verify_standard_callbacks(c.new, :create, :update, :destroy, :find)
    end
    
    it 'should allow adding to an association to succeed when granted' do
      c = new_model_class
      c.instance_eval do
        has_many :users
        has_and_belongs_to_many :groups
        grant(:add => [:users, :groups]) { true }
      end
      instance = c.new
      lambda { instance.grant_add_users(new_model_class) }.should_not raise_error(Grant::Error)
      lambda { instance.grant_remove_users(new_model_class) }.should raise_error(Grant::Error)
      lambda { instance.grant_add_groups(new_model_class) }.should_not raise_error(Grant::Error)
      lambda { instance.grant_remove_groups(new_model_class) }.should raise_error(Grant::Error)
    end
    
    it 'should allow removing from an association to succeed when granted' do
      c = new_model_class
      c.instance_eval do
        has_many :users
        has_and_belongs_to_many :groups
        grant(:remove => [:users, :groups]) { true }
      end
      instance = c.new
      lambda { instance.grant_add_users(new_model_class) }.should raise_error(Grant::Error)
      lambda { instance.grant_remove_users(new_model_class) }.should_not raise_error(Grant::Error)
      lambda { instance.grant_add_groups(new_model_class) }.should raise_error(Grant::Error)
      lambda { instance.grant_remove_groups(new_model_class) }.should_not raise_error(Grant::Error)
    end
  end
  
  def verify_standard_callbacks(instance, *succeeding_callbacks)
    succeeding_callbacks = Array(succeeding_callbacks)
    [:create, :update, :destroy, :find].each do |action|
      expectation = succeeding_callbacks.include?(action) ? :should_not : :should
      lambda { instance.send(action) }.send(expectation, raise_error(Grant::Error))
    end
  end
  
  def new_model_class
    Class.new(ActiveRecordMock) do
      include Grant::ModelSecurity
    end
  end
  
  class ActiveRecordMock
    def id; 1 end
    
    def self.before_create(method)
      define_method(:create) { send method }
    end
    
    def self.before_update(method)
      define_method(:update) { send method }
    end
    
    def self.before_destroy(method)
      define_method(:destroy) { send method }
    end
    
    def self.after_find(method)
      define_method(:find) { send method }
    end
    
    def self.has_many(association_id, options, &extension)
      define_method("add_#{association_id}".to_sym) do |associated_model|
        Array(options[:before_add]).each { |callback| callback.call(associated_model) }
      end
      define_method("remove_#{association_id}".to_sym) do |associated_model|
        Array(options[:before_remove]).each { |callback| callback.call(associated_model) }
      end
    end
    
    def self.has_and_belongs_to_many(association_id, options, &extension)
      define_method("add_#{association_id}".to_sym) do |associated_model|
        Array(options[:before_add]).each { |callback| callback.call(associated_model) }
      end
      define_method("remove_#{association_id}".to_sym) do |associated_model|
        Array(options[:before_remove]).each { |callback| callback.call(associated_model) }
      end
    end
  end
  
end
