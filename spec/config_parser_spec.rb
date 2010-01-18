require 'spec_helper'
require 'grant/config_parser'

describe Grant::ConfigParser do
  include Grant::ConfigParser
  
  describe 'Configuration' do
    it "should parse actions, associations, and options from a config array" do
      config = extract_config([:create, 'update', {:add => [:people, :places], 'remove' => :people, :only => :username}])
      config.should_not be_nil
      config.should have(3).items
      config[0].should =~ [:create, :update]
      config[1].should == {:add => [:people, :places], :remove => :people}
      config[2].should == {:only => :username}
    end
  
    it "should parse actions, associations, and options from a config array when associatins are absent" do
      config = extract_config([:create, :update, {'except' => :ssn}])
      config.should_not be_nil
      config.should have(3).items
      config[0].should =~ [:create, :update]
      config[1].should == {}
      config[2].should == {:except => :ssn}
    end
    
    it "should parse actions, associations, and options from a config array when options are absent" do
      config = extract_config([:create, 'update', {:add => ['people', :places]}])
      config.should_not be_nil
      config.should have(3).items
      config[0].should =~ [:create, :update]
      config[1].should == {:add => ['people', :places]}
      config[2].should == {}
    end
    
    it "should parse actions" do
      config = extract_config([:create])
      config.should_not be_nil
      config.should have(3).items
      config[0].should =~ [:create]
      config[1].should == {}
      config[2].should == {}
    end

  end
  
  describe 'Configuration Validation' do
    it "should raise a Grant::Error if no action or association is specified" do
      lambda {
        self.instance_eval { validate_config([], {}, {}) }
      }.should raise_error(Grant::Error)
    end
    
    it "should raise a Grant::Error if an invalid action is specified" do
      lambda {
        self.instance_eval { validate_config([:create, :udate], {:add => [:people, :places]}, {}) }
      }.should raise_error(Grant::Error)
    end
    
    it "should raise a Grant::Error if an invalid association is specified" do
      lambda {
        self.instance_eval { validate_config([:destroy], {:add => :people, :update => :places}, {:except => :ssn}) }
      }.should raise_error(Grant::Error)
    end
    
    it "should raise a Grant::Error if both the except and only options are specified" do
      lambda {
        self.instance_eval { validate_config([:find], {:add => :people}, {:except => :ssn, :only => :username}) }
      }.should raise_error(Grant::Error)
    end
  end
  
end