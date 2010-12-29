require File.dirname(__FILE__) + '/spec_helper'
require 'grant'

describe Grant::ConfigParser do
  
  describe 'Configuration' do
    it "should parse actions and associations from a config array" do
      config = Grant::ConfigParser.extract_config([:create, 'update', {:add => [:people, :places], 'remove' => :people}])
      config.should_not be_nil
      config.should have(2).items
      config[0].should =~ [:create, :update]
      config[1].should == {:add => [:people, :places], :remove => :people}
    end
  
    it "should parse actions from a config array when associations are absent" do
      config = Grant::ConfigParser.extract_config([:create, :update])
      config.should_not be_nil
      config.should have(2).items
      config[0].should =~ [:create, :update]
      config[1].should == {}
    end
    
    it "should parse actions and associations from a config array when options are absent" do
      config = Grant::ConfigParser.extract_config([:create, 'update', {:add => ['people', :places]}])
      config.should_not be_nil
      config.should have(2).items
      config[0].should =~ [:create, :update]
      config[1].should == {:add => ['people', :places]}
    end
    
    it "should parse actions" do
      config = Grant::ConfigParser.extract_config([:create])
      config.should_not be_nil
      config.should have(2).items
      config[0].should =~ [:create]
      config[1].should == {}
    end

  end
  
  describe 'Configuration Validation' do
    it "should raise a Grant::Error if no action or association is specified" do
      lambda {
        Grant::ConfigParser.instance_eval { validate_config([], {}) }
      }.should raise_error(Grant::Error)
    end
    
    it "should raise a Grant::Error if an invalid action is specified" do
      lambda {
        Grant::ConfigParser.instance_eval { validate_config([:create, :udate], {:add => [:people, :places]}) }
      }.should raise_error(Grant::Error)
    end
    
    it "should raise a Grant::Error if an invalid association is specified" do
      lambda {
        Grant::ConfigParser.instance_eval { validate_config([:destroy], {:add => :people, :update => :places}) }
      }.should raise_error(Grant::Error)
    end
  end
  
end