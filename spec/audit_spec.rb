require File.dirname(__FILE__) + '/spec_helper'

describe Audit do
  
  describe 'Validation' do
    it "should be valid given valid attributes" do
      Audit.new(
        :auditable_id => 1, 
        :auditable_type => 'User', 
        :user_id => 1, 
        :user_type => 'User', 
        :action => 'create', 
        :success => true
      ).should be_valid
    end
    
    it "should not be valid if not given all valid attributes" do
      Audit.new(
        :auditable_type => 'User', 
        :user_id => 1, 
        :user_type => 'User', 
        :action => 'create', 
        :success => true
      ).should_not be_valid
      
      Audit.new(
        :auditable_id => 1, 
        :user_id => 1, 
        :user_type => 'User', 
        :action => 'create', 
        :success => true
      ).should_not be_valid
      
      Audit.new(
        :auditable_id => 1, 
        :auditable_type => 'User', 
        :user_type => 'User', 
        :action => 'create', 
        :success => true
      ).should_not be_valid
      
      Audit.new(
        :auditable_id => 1, 
        :auditable_type => 'User', 
        :user_id => 1, 
        :action => 'create', 
        :success => true
      ).should_not be_valid
      
      Audit.new(
        :auditable_id => 1, 
        :auditable_type => 'User', 
        :user_id => 1, 
        :user_type => 'User', 
        :success => true
      ).should_not be_valid
      
      Audit.new(
        :auditable_id => 1, 
        :auditable_type => 'User', 
        :user_id => 1, 
        :user_type => 'User', 
        :action => 'create'
      ).should_not be_valid
    end
  end
  
end