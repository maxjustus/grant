class ActiveRecordMock
  def self.column_names
    ['name', 'stuff', 'other_attr', 'ungranted_attr', 'create']
  end

  def id; 1 end

  def name
    'thing'
  end

  def attribute_names
    ['name', 'stuff', 'other_attr', 'ungranted_attr', 'create']
  end

  def changed
    ['name', 'stuff']
  end

  def self.before_save(method)
    alias_method :before_save_create, :create
    alias_method :before_save_update, :update
    define_method(:create) { send :before_save_create; send method }
    define_method(:update) { send :before_save_update; send method }
  end

  def create
  end

  def update
  end

  def self.before_create(method)
    alias_method :orig_create, :create
    define_method(:create) { send :orig_create; send method }
  end

  def self.before_update(method)
    alias_method :orig_update, :update
    define_method(:update) { send :orig_update; send method }
  end

  def self.before_destroy(method)
    define_method(:destroy) { send method }
  end

  def self.after_find(method)
    define_method(:find) { send method }
  end
end
