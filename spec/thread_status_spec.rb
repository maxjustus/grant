require File.dirname(__FILE__) + '/spec_helper'

describe Grant::ThreadStatus do
  it "should be enabled if set to enabled" do
    Grant::ThreadStatus.enable
    Grant::ThreadStatus.should be_enabled
    Grant::ThreadStatus.should_not be_disabled
  end
  
  it "should be disabled if set to disabled" do
    Grant::ThreadStatus.disable
    Grant::ThreadStatus.should_not be_enabled
    Grant::ThreadStatus.should be_disabled
  end
end