require File.dirname(__FILE__) + '/spec_helper'
require 'grant'

describe Grant::ConfigParser do
  
  describe 'Configuration' do
    it "should parse actions from a config array" do
      config = Grant::ConfigParser.extract_config([:create, 'update'])
      config.should_not be_nil
      config.should =~ [:create, :update]
    end
  
    it "should parse actions" do
      config = Grant::ConfigParser.extract_config([:create])
      config.should_not be_nil
      config.should =~ [:create]
    end
  end
  
  describe 'Configuration Validation' do
    it "should raise a Grant::Error if no action is specified" do
      lambda {
        Grant::ConfigParser.instance_eval { validate_config([]) }
      }.should raise_error(Grant::Error)
    end
    
    it "should raise a Grant::Error if an invalid action is specified" do
      lambda {
        Grant::ConfigParser.instance_eval { validate_config([:create, :udate]) }
      }.should raise_error(Grant::Error)
    end
  end
  
end