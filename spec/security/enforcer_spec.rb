require 'spec_helper'
require 'grant/security/enforcer'

describe Grant::Security::Enforcer do
  before(:each) do
    @enforcer = Grant::Security::Enforcer.new
    @model = Model.new(1)
  end
  
  describe 'Non-association Security' do
    it 'should allow create, find, update, and destroy actions when the grant statement permits' do
      @enforcer.enforce([:create, :find, :update, :destroy]) { true } 
      lambda {
        @enforcer.before_create(@model)
        @enforcer.before_update(@model)
        @enforcer.before_destroy(@model)
        @enforcer.after_find(@model)
      }.should_not raise_error
    end
    
    it 'should deny create, find, update, and destroy actions when the grant statement does not permit' do
      @enforcer.enforce([:create, :find, :update, :destroy]) { false } 
      
      lambda { @enforcer.before_create(@model) }.should raise_error(Grant::Error)
      lambda { @enforcer.before_update(@model) }.should raise_error(Grant::Error)
      lambda { @enforcer.before_destroy(@model) }.should raise_error(Grant::Error)
      lambda { @enforcer.after_find(@model) }.should raise_error(Grant::Error)
    end
    
    it "should deny any action if not explicitly granted, but other actions are granted" do
      @enforcer.enforce([:create]) { true }
      
      lambda { @enforcer.before_create(@model) }.should_not raise_error(Grant::Error)
      lambda { @enforcer.before_update(@model) }.should raise_error(Grant::Error)
      lambda { @enforcer.before_destroy(@model) }.should raise_error(Grant::Error)
      lambda { @enforcer.after_find(@model) }.should raise_error(Grant::Error)
    end
    
    it "should not deny any action if no grant statements are present in the class" do
      lambda {
        @enforcer.before_create(@model)
        @enforcer.before_update(@model)
        @enforcer.before_destroy(@model)
        @enforcer.after_find(@model)
      }.should_not raise_error
    end
  end
  
  describe 'Association Security' do
    it 'should allow add and remove actions when the grant statement permits' do
      @enforcer.enforce([{:add => [:people, :places], :remove => :places}]) { true } 
      
      lambda {
        @enforcer.before_add_association(:people, @model, Model.new(2))
        @enforcer.before_add_association(:places, @model, Model.new(2))
        @enforcer.before_remove_association(:places, @model, Model.new(2))
      }.should_not raise_error
    end
    
    it 'should deny add and remove actions when the grant statement does not permit' do
      @enforcer.enforce([{:add => [:people, :places], :remove => :places}]) { false } 
      
      lambda { @enforcer.before_add_association(:people, @model, Model.new(2)) }.should raise_error(Grant::Error)
      lambda { @enforcer.before_add_association(:places, @model, Model.new(2)) }.should raise_error(Grant::Error)
      lambda { @enforcer.before_remove_association(:places, @model, Model.new(2)) }.should raise_error(Grant::Error)
    end
    
    it "should deny any action if not explicitly granted, but other actions are granted" do
      @enforcer.enforce([:create]) { true }       
      
      lambda { @enforcer.before_create(@model) }.should_not raise_error
      lambda { @enforcer.before_add_association(:people, @model, Model.new(2)) }.should raise_error(Grant::Error)
      lambda { @enforcer.before_add_association(:places, @model, Model.new(2)) }.should raise_error(Grant::Error)
      lambda { @enforcer.before_remove_association(:places, @model, Model.new(2)) }.should raise_error(Grant::Error)
    end
  end
  
  class Model
    attr_accessor :id
    def initialize(id)
      self.id = id
    end
  end

end