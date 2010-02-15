require 'grant'

describe Grant::ModelSecurity do
  
  describe 'module include' do
    it 'should establish failing ActiveRecord callbacks for before_create, before_update, before_destroy, and after_find when included' do
      class TestModel; end
      TestModel.stub!(:has_and_belongs_to_many)
      TestModel.stub!(:has_many)
      TestModel.should_receive(:before_create).with(:grant_before_create)
      TestModel.should_receive(:before_update).with(:grant_before_update)
      TestModel.should_receive(:before_destroy).with(:grant_before_destroy)
      TestModel.should_receive(:after_find).with(:grant_after_find)
      TestModel.instance_eval do
        include Grant::ModelSecurity
      end
      instance = TestModel.new
      lambda { instance.grant_before_create }.should raise_error(Grant::Error)
      lambda { instance.grant_before_update }.should raise_error(Grant::Error)
      lambda { instance.grant_before_destroy }.should raise_error(Grant::Error)
      lambda { instance.grant_after_find }.should raise_error(Grant::Error)
    end
    
    it 'should establish failing ActiveRecord callbacks for any has_many or has_and_belongs_to_many associations' do
      c = new_model_class
      c.instance_eval do
        has_many :users
        has_and_belongs_to_many :groups
      end
      instance = c.new
      lambda { instance.grant_add_users }.should raise_error(Grant::Error)
      lambda { instance.grant_remove_users }.should raise_error(Grant::Error)
      lambda { instance.grant_add_groups }.should raise_error(Grant::Error)
      lambda { instance.grant_remove_groups }.should raise_error(Grant::Error)
    end
  end
  
  describe '#grant' do
    it 'should allow after_find callback to succeed when granted' do
      verify_standard_callbacks(:update)
    end
    
    it 'should allow before_create callback to succeed when granted' do
      verify_standard_callbacks(:create)
    end
    
    it 'should allow before_update callback to succeed when granted' do
      verify_standard_callbacks(:destroy)
    end
    
    it 'should allow before_destroy callback to succeed when granted' do
      verify_standard_callbacks(:destroy)
    end
    
    it 'should allow multiple callbacks to be specified with one grant statment' do
      verify_standard_callbacks(:create, :update)
      verify_standard_callbacks(:create, :update, :destroy)
      verify_standard_callbacks(:create, :update, :destroy, :find)
    end
    
    it 'should allow adding to an association to succeed when granted' do
      c = new_model_class
      c.instance_eval do
        has_many :users
        has_and_belongs_to_many :groups
        grant(:add => [:users, :groups]) { true }
      end
      instance = c.new
      lambda { instance.grant_add_users }.should_not raise_error(Grant::Error)
      lambda { instance.grant_remove_users }.should raise_error(Grant::Error)
      lambda { instance.grant_add_groups }.should_not raise_error(Grant::Error)
      lambda { instance.grant_remove_groups }.should raise_error(Grant::Error)
    end
    
    it 'should allow removing from an association to succeed when granted' do
      c = new_model_class
      c.instance_eval do
        has_many :users
        has_and_belongs_to_many :groups
        grant(:remove => [:users, :groups]) { true }
      end
      instance = c.new
      lambda { instance.grant_add_users }.should raise_error(Grant::Error)
      lambda { instance.grant_remove_users }.should_not raise_error(Grant::Error)
      lambda { instance.grant_add_groups }.should raise_error(Grant::Error)
      lambda { instance.grant_remove_groups }.should_not raise_error(Grant::Error)
    end
    
    def verify_standard_callbacks(*succeeding_callbacks)
      succeeding_callbacks = Array(succeeding_callbacks)
      c = new_model_class
      c.instance_eval do
        grant(*succeeding_callbacks)
      end
      instance = c.new
      [:create, :update, :destroy, :find].each do |callback|
        grant_callback = "grant_" + (callback == :find ? "after_" : "before_") + callback.to_s
        expectation = succeeding_callbacks.include?(callback) ? :should_not : :should
        lambda { instance.send(grant_callback.to_sym) }.send(expectation, raise_error(Grant::Error))
      end
    end
  end
  
  def new_model_class
    c = Class.new do
      def self.has_and_belongs_to_many(association_id, options={}, &extension); end
      def self.has_many(association_id, options={}, &extension); end
      def self.before_create(*args); end
      def self.before_update(*args); end
      def self.before_destroy(*args); end
      def self.after_find(*args); end
    end
    Class.new(c) do
      include Grant::ModelSecurity
    end
  end
  
end
