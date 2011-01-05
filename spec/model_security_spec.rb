require File.dirname(__FILE__) + '/spec_helper'
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
  end
  
  describe '#grant' do
    it 'should allow after_find callback to succeed when granted' do
      c = new_model_class.instance_eval { grant(:find) { true }; self }
      verify_standard_callbacks(c.new, :find)
    end
    
    it 'should allow before_create callback to succeed when granted' do
      c = new_model_class.instance_eval { grant(:create) { true }; self }
      verify_standard_callbacks(c.new, :create)
    end
    
    it 'should allow before_update callback to succeed when granted' do
      c = new_model_class.instance_eval { grant(:update) { true }; self }
      verify_standard_callbacks(c.new, :update)
    end
    
    it 'should allow before_destroy callback to succeed when granted' do
      c = new_model_class.instance_eval { grant(:destroy) { true }; self }
      verify_standard_callbacks(c.new, :destroy)
    end
    
    it 'should allow multiple callbacks to be specified with one grant statment' do
      c = new_model_class.instance_eval { grant(:create, :update) { true }; self }
      verify_standard_callbacks(c.new, :create, :update)
      
      c = new_model_class.instance_eval { grant(:create, :update, :destroy) { true }; self }
      verify_standard_callbacks(c.new, :create, :update, :destroy)
      
      c = new_model_class.instance_eval { grant(:create, :update, :destroy, :find) { true }; self }
      verify_standard_callbacks(c.new, :create, :update, :destroy, :find)
    end
  end
    
  def verify_standard_callbacks(instance, *succeeding_callbacks)
    verify_callbacks([:create, :update, :destroy, :find], instance, nil, succeeding_callbacks)
  end
  
  def verify_callbacks(all_actions, instance, associated_model, succeeding_callbacks)
    all_actions.each do |action|
      expectation = succeeding_callbacks.include?(action) ? :should_not : :should
      lambda { instance.send(action, associated_model) }.send(expectation, raise_error(Grant::Error))
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
  end
  
end
