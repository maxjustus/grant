require File.dirname(__FILE__) + '/spec_helper'
require 'grant'

describe Grant::ConfigParser do
  before do
    @resource = ActiveRecordMock
  end
  
  describe 'Configuration' do
    it "should parse actions from a config array" do
      config = Grant::ConfigParser.extract_config([:create, 'update'], @resource)
      config[:actions].should =~ [:create, :update]
    end
  
    it "should parse actions" do
      config = Grant::ConfigParser.extract_config([:create], @resource)
      config[:actions].should =~ [:create]
    end

    it "should parse attributes" do
      config = Grant::ConfigParser.extract_config([:name], @resource)
      config[:attributes].should =~ [:name]
    end

    it "should parse arguments as strings" do
      config = Grant::ConfigParser.extract_config(['create', 'name'], @resource)
      config[:attributes].should =~ [:name]
      config[:actions].should =~ [:create]
    end

    it "should parse attributes with actions" do
      config = Grant::ConfigParser.extract_config([:create, :name], @resource)
      config[:attributes].should =~ [:name]
      config[:actions].should =~ [:create]
    end

    it "should parse actions with attributes specified using :attributes" do
      config = Grant::ConfigParser.extract_config([:create, {:attributes => [:name, :stuff]}], @resource)
      config[:attributes].should =~ [:name, :stuff]
      config[:actions].should =~ [:create]
    end

    it "should parse actions with attributes specified using :attributes and as normal arguments" do
      config = Grant::ConfigParser.extract_config([:create, :stuff, {:attributes => [:create, :stuff]}], @resource)
      config[:attributes].should =~ [:create, :stuff]
      config[:actions].should =~ [:create]
    end

    it "should parse :attributes => :all and return every attribute" do
      config = Grant::ConfigParser.extract_config([:create, {:attributes => :all}], @resource)
      config[:attributes].should =~ @resource.column_names.collect {|c| c.to_sym}

      config = Grant::ConfigParser.extract_config(['create', {'attributes' => 'all'}], @resource)
      config[:actions].should =~ [:create]
      config[:attributes].should =~ @resource.column_names.collect {|c| c.to_sym}
    end

    it "should parse actions with attributes specified using :attributes which are identical to action names" do
      config = Grant::ConfigParser.extract_config([:create, :update, {:attributes => [:create]}], @resource)
      config[:attributes].should =~ [:create]
      config[:actions].should =~ [:create, :update]
    end
  end
  
  describe 'Configuration Validation' do
    it "should raise a Grant::Error if no action is specified" do
      resource = @resource
      lambda {
        Grant::ConfigParser.instance_eval { validate_config({}, resource) }
      }.should raise_error(Grant::Error)
    end

    it "should raise a Grant::Error if an invalid action is specified" do
      resource = @resource
      lambda {
        Grant::ConfigParser.instance_eval { validate_config({:actions => [:create, :udate]}, resource) }
      }.should raise_error(Grant::Error)
    end

    it "should raise a Grant::Error if an invalid attribute is specified" do
      resource = @resource
      lambda {
        Grant::ConfigParser.instance_eval { validate_config({:actions => [:create], :attributes => [:guy, :stuff]}, resource) }
      }.should raise_error(Grant::Error)
    end
  end
  
end
