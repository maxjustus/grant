module Grant
  module Base
    module ClassMethods
      
      def grant_disabled?
        Grant::ThreadStatus.disabled?
      end
      
      def without_grant
        previously_disabled = Grant::ThreadStatus.disabled?
        Grant::ThreadStatus.disable unless previously_disabled

        begin
          result = yield if block_given?
        ensure
          Grant::ThreadStatus.enable unless previously_disabled
        end

        result
      end
      
    end
  end
end