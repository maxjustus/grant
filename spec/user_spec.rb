require File.dirname(__FILE__) + '/spec_helper'
require 'grant/user'

describe Grant::User do
  it "should return the same user that's set on the same thread" do
    user = "user"
    Grant::User.current_user = user
    Grant::User.current_user.should == user
  end
  
  it "should not return the same user from a different thread" do
    user = "user"
    user2 = "user2"
    
    Grant::User.current_user = user
    
    Thread.new do
      Grant::User.current_user.should be_nil
      Grant::User.current_user = user2
      Grant::User.current_user.should == user2
    end
    
    Grant::User.current_user.should == user
  end
end