require 'grant'

module GrantHelpers
    
  def current_user=(user)
    Grant::User.current_user = user
  end
  
  def current_user
    Grant::User.current_user
  end
  
  def clear_current_user
    Grant::User.current_user = nil
  end
  
  def verify_audit(audit, audited, user, action, changes_nil=false, message_nil=true, success=true)
    audit.auditable_id.should == audited.id
    audit.auditable_type.should == audited.class.name
    audit.user_id.should == user.id
    audit.user_type.should == user.class.name
    audit.action.should == action.to_s
    audit.success.should be_true if success
    audit.success.should be_false unless success
    audit.message.should be_nil if message_nil
    audit.message.should_not be_nil unless message_nil
    audit.changes.should be_nil if changes_nil
    audit.changes.should_not be_nil unless changes_nil
  end
  
end


