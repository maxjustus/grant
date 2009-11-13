require File.dirname(__FILE__) + '/spec_helper'

describe Grant::ModelSecurityManager do
  
  before(:all) do
    Audit.instance_eval { include Grant::ModelSecurity }
  end
  
  before(:each) do
    Grant::User.current_user = Audit.new
    @msm = Grant::ModelSecurityManager.new
    Grant::ThreadStatus.enable
  end
  
  after(:each) do
    Grant::User.current_user = nil
    Grant::ThreadStatus.disable
  end
  
  describe '#validate_proc' do
    it "should validate that a non-nil block is passed for callback" do
      lambda {
        @msm.instance_eval { validate_proc nil }
      }.should raise_error(Grant::ModelSecurityError)
      
      lambda {
        @msm.instance_eval { validate_proc Proc.new {} }
      }.should_not raise_error(Grant::ModelSecurityError)
    end
  end
    
  describe '#validate_actions' do
    it "should validate that a variable number of actions passed to the block are valid ones" do
      lambda {
        @msm.instance_eval do
          validate_actions(:create)
          validate_actions(:create, :find)
          validate_actions(:create, :find, :update)
          validate_actions(:create, :find, :update, :destroy)
          validate_actions(:create, :find, :update, :destroy, :add)
          validate_actions(:create, :find, :update, :destroy, :add, :remove)
        end
      }.should_not raise_error(Grant::ModelSecurityError)
      
      lambda {
        @msm.instance_eval do
          validate_actions(:read)
        end
      }.should raise_error(Grant::ModelSecurityError)
    end
  end
  
  describe '#apply_security' do
    it "should allow an action if a callback allows it" do
      callback = Proc.new { true }
      lambda {
        @msm.add_callback(callback, :create)
        @msm.before_create(Audit.new)
        
        @msm.add_callback(callback, :update)
        @msm.before_update(Audit.new)
        
        @msm.add_callback(callback, :destroy)
        @msm.before_destroy(Audit.new)
        
        @msm.add_callback(callback, :find)
        @msm.after_find(Audit.new)
      }.should_not raise_error
    end
    
    it "should throw an error unless a callback explicitly allows an action" do
      callback = Proc.new { false }
      
      lambda {
        @msm.add_callback(callback, :create)
        @msm.before_create(Audit.new)
      }.should raise_error(Grant::ModelSecurityError)
      
      lambda {
        @msm.add_callback(callback, :update)
        @msm.before_update(Audit.new)
      }.should raise_error(Grant::ModelSecurityError)
      
      lambda {
        @msm.add_callback(callback, :destroy)
        @msm.before_destroy(Audit.new)
      }.should raise_error(Grant::ModelSecurityError)
      
      lambda {
        @msm.add_callback(callback, :find)
        @msm.after_find(Audit.new)
      }.should raise_error(Grant::ModelSecurityError)
    end
  end
  
  describe '#apply_association_security' do
    it "should allow an action if a callback allows it" do
      callback = Proc.new { true }
      lambda {
        @msm.add_callback(callback, :add => :audits)
        @msm.before_add_association(:audits, Audit.new, Audit.new)
        
        @msm.add_callback(callback, :remove => :audits)
        @msm.before_remove_association(:audits, Audit.new, Audit.new)
      }.should_not raise_error
    end
    
    it "should throw an error unless a callback explicitly allows an action" do
      callback = Proc.new { false }
      lambda {
        @msm.add_callback(callback, :add => :audits)
        @msm.before_add_association(:audits, Audit.new, Audit.new)
      }.should raise_error(Grant::ModelSecurityError)
      
      lambda {
        @msm.add_callback(callback, :remove => :audits)
        @msm.before_remove_association(:audits, Audit.new, Audit.new)
      }.should raise_error(Grant::ModelSecurityError)
    end
  end
  
end