require 'spec_helper'
require 'grant/constraint'

describe Grant::Constraint do
  
  describe 'initialize' do
    it 'should raise an ArgumentError is an action is not passed as the first parameter' do
      lambda {
        Grant::Constraint.new() { true }
      }.should raise_error(ArgumentError)
    end
    
    it 'should raise an ArgumentError is a block is not passed as the last parameter' do
      lambda {
        Grant::Constraint.new(:create)
      }.should raise_error(ArgumentError)
    end
    
    it 'should not raise any error if an action is passed as the first parameter and a block as the last' do
      lambda {
        Grant::Constraint.new(:create) { true }
      }.should_not raise_error
    end
  end
  
  describe 'permit?' do
    it 'should ignore actions it was not initialized for' do
      c = Grant::Constraint.new(:create) { true }
      c.should_not be_permitted(:update, Model.new(1))
    end
    
    it 'should allow actions it was initialized to permit' do
      c = Grant::Constraint.new(:create) { true }
      c.should be_permitted(:create, Model.new(1))
    end
    
    it 'should not allow actions it was initialized to deny' do
      c = Grant::Constraint.new(:create) { false }
      c.should_not be_permitted(:create, Model.new(1))
    end
    
    it 'should ignore association actions it was not initialized for' do
      c = Grant::Constraint.new(:create, :id) { true }
      c.should_not be_permitted(:create, Model.new(1), :other, Model.new(2))
    end
    
    it 'should allow association actions it was initialized to permit' do
      c = Grant::Constraint.new(:create, :id) { true }
      c.should be_permitted(:create, Model.new(1), :id, Model.new(2))
    end
    
    it 'should not allow association actions it was initialized to deny' do
      c = Grant::Constraint.new(:create, :id) { false }
      c.should_not be_permitted(:create, Model.new(1), :id, Model.new(2))
    end
  end
  
  class Model
    attr_accessor :id
    def initialize(id)
      self.id = id
    end
  end
  
end
