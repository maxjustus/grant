require 'grant/integration'

module Grant
  module SpecHelpers
    include Grant::Integration
  
    def self.included(base)
      base.class_eval do
        before(:each) do
          disable_grant
        end
      
        after(:each) do
          enable_grant
        end
      end
    end
    
  end
end


