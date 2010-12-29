require File.dirname(__FILE__) + '/spec_helper'
require 'grant'

describe Grant::Integration do
  include Grant::Integration
  
  it "should have the ability to disable Grant" do
    disable_grant
    grant_disabled?.should be_true
    Grant::ThreadStatus.should be_disabled
  end
  
  it "should have the ability to enable Grant" do
    disable_grant
    enable_grant
    grant_enabled?.should be_true
    Grant::ThreadStatus.should be_enabled  
  end
  
  it "should have the ability to check if grant is enabled" do
    enable_grant
    grant_enabled?.should be_true
  end
  
  it "should have the ability to check if grant is disabled" do
    disable_grant
    grant_disabled?.should be_true
  end
  
  it "should be able to execute a block of code with grant temporarily disabled but switched back to enabled afterwards" do
    enable_grant
    without_grant do
      grant_disabled?.should be_true
      Grant::ThreadStatus.should be_disabled
    end
    grant_enabled?.should be_true
  end
  
  it "should be able to execute a block of code with grant disabled and remain disabled afterwards if it was beforehand" do
    disable_grant
    without_grant do
      grant_disabled?.should be_true
      Grant::ThreadStatus.should be_disabled
    end
    grant_disabled?.should be_true
  end
  
  it "should be able to execute a block of code with grant temporarily enabled but switched back to disabled afterwards" do
    disable_grant
    with_grant do
      grant_enabled?.should be_true
      Grant::ThreadStatus.should be_enabled
    end
    grant_disabled?.should be_true
  end
  
  it "should be able to execute a block of code with grant enabled and remain enabled afterwards if it was beforehand" do
    enable_grant
    with_grant do
      grant_enabled?.should be_true
      Grant::ThreadStatus.should be_enabled
    end
    grant_enabled?.should be_true
  end
  
end