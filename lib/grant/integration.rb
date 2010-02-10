require 'grant/thread_status'

module Grant
  module Integration
    
    def without_grant
      previously_disabled = grant_disabled?
      disable_grant
      
      begin
        result = yield if block_given?
      ensure
        enable_grant unless previously_disabled
      end
      
      result
    end
    
    def disable_grant
      Grant::ThreadStatus.disable
    end
    
    def enable_grant
      Grant::ThreadStatus.enable
    end
    
    def grant_disabled?
      Grant::ThreadStatus.disabled?
    end
    
    def grant_enabled?
      Grant::ThreadStatus.enabled?
    end
    
  end
end