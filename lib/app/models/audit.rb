class Audit < ActiveRecord::Base
  validates_presence_of :auditable_id,
                        :auditable_type,
                        :user_id,
                        :user_type,
                        :action,
                        :success
  
  validates_inclusion_of :action,
                         :in => %w{ find create update destroy },
                         :message => "valid actions are find, create, update, or destroy"

  serialize :changes
end
