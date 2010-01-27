class <%= class_name %> < ActiveRecord::Migration
  def self.up
    create_table :audits, :force => true do |t|
      t.column :auditable_id, :integer
      t.column :auditable_type, :string
      t.column :auditable_version, :integer
      t.column :user_id, :integer
      t.column :user_type, :string
      t.column :action, :string
      t.column :success, :boolean
      t.column :message, :text
      t.column :changes, :text
      t.column :created_at, :datetime
    end
  end

  def self.down
    drop_table :audits
  end
end
