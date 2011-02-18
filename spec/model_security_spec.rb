require File.dirname(__FILE__) + '/spec_helper'
require 'grant'

describe Grant::ModelSecurity do
  
  before(:each) do
    Grant::User.current_user = (Class.new do
      def id; 1 end
      def auth_level; 10 end
    end).new
  end
  
  describe 'module include' do
    it 'should establish failing ActiveRecord callbacks for before_save, before_create, before_update, before_destroy, and after_find when included' do
      verify_standard_callbacks(new_model_class.new)
    end
  end

  describe '#grant' do
    it 'should allow after_find callback to succeed when granted' do
      c = new_model_class.instance_eval { grant(:find) { true }; self }
      verify_standard_callbacks(c.new, :find)
    end
    
    it 'should allow before_create callback to succeed when granted' do
      c = new_model_class.instance_eval do
        grant(:create, :attributes => :all) { true }
        self
      end
      verify_standard_callbacks(c.new, :create)
    end
    
    it 'should allow before_update callback to succeed when granted' do
      c = new_model_class.instance_eval do
        grant(:update, :attributes => [:name, :stuff]) { true }
        self
      end
      verify_standard_callbacks(c.new, :update)
    end
    
    it 'should allow before_destroy callback to succeed when granted' do
      c = new_model_class.instance_eval { grant(:destroy) { true }; self }
      verify_standard_callbacks(c.new, :destroy)
    end

    it 'should raise a grant error for unsaved models' do
      c = new_model_class.class_eval do
        def id
          nil
        end

        self
      end

      c.instance_eval do
        grant(:create) {false}
      end

      lambda { c.new.send(:create) }.should(raise_error(Grant::Error, 'create permission not granted to :1 for resource new '))
    end

    it 'should raise a grant error for nil users' do
      Grant::User.current_user = nil
      c = new_model_class

      lambda { c.new.send(:create) }.should(raise_error(Grant::Error, 'create permission not granted to unlogged in user for resource :1'))
    end
    
    it 'should allow multiple callbacks to be specified with one grant statement' do
      c = new_model_class.instance_eval { grant(:create, :update, :attributes => :all) { true }; self }
      verify_standard_callbacks(c.new, :create, :update)
      
      c = new_model_class.instance_eval { grant(:create, :update, :destroy, :attributes => :all) { true }; self }
      verify_standard_callbacks(c.new, :create, :update, :destroy)
      
      c = new_model_class.instance_eval { grant(:create, :update, :destroy, :find, :attributes => :all) { true }; self }
      verify_standard_callbacks(c.new, :create, :update, :destroy, :find)
    end

    it 'should allow update of attributes specified using grant' do
      c = new_model_class.instance_eval do
        grant(:create, :update, :name) { true }
        grant(:stuff, :other_attr) { true }
        self
      end
      verify_standard_callbacks(c.new, :create, :update)
    end

    it 'should pass current_user and model to block' do
      c = new_model_class.instance_eval do
        grant(:create, :update, :name, :stuff, :other_attr) {|user, model| user.auth_level == 10 && model.name == 'thing' }
        self
      end

      verify_standard_callbacks(c.new, :create, :update)
    end

    it 'should be restrictive rather then permissive' do
      c = new_model_class.instance_eval do
        grant(:name) { true }
        self
      end
      verify_standard_callbacks(c.new)
    end

    it 'should respect grant_disabled' do
      c = new_model_class.instance_eval do
        grant(:name) { false }
        grant(:find) { false }
        self
      end

      c.class_eval do
        def grant_disabled?
          true
        end
      end

      verify_standard_callbacks(c.new, :create, :update, :find, :destroy)

      c = new_model_class

      c.class_eval do
        def grant_disabled?
          true
        end
      end

      verify_standard_callbacks(c.new, :create, :update, :find, :destroy)
    end

    it 'should allow update if nothing is changed' do
      c = new_model_class.instance_eval do
        grant(:name) { false }
        grant(:update, :create, :stuff, :other_attr) { true }

        self
      end
      @c = c.new
      @c.instance_eval do
        def changed
          []
        end
      end

      verify_standard_callbacks(@c, :create, :update)
    end

    it 'should deny update of attributes where grant user may not update a changed attribute' do
      c = new_model_class.instance_eval do
        grant(:name) { false }
        grant(:stuff, :other_attr) { true }
        self
      end

      verify_standard_callbacks(c.new)
    end

    it 'should deny update of attributes when nil is used as the return value for block' do
      c = new_model_class.instance_eval do
        grant(:name, :stuff, :other_attr) { true }
        grant(:name) { nil }
        self
      end

      verify_standard_callbacks(c.new)
    end

    it 'should allow multiple attributes to be specified with one grant statement' do
      c = new_model_class.instance_eval do
        grant(:create, :update) { true }
        grant(:name, :stuff, :other_attr) { true }
        self
      end
      verify_standard_callbacks(c.new, :create, :update)

      c = new_model_class.instance_eval do
        grant(:name, :stuff) { false }
        grant(:other_attr) { true }
        self
      end
      verify_standard_callbacks(c.new)
    end
  end

  describe '#granted' do
    before do
      c = new_model_class.instance_eval do
        grant(:create) { true }
        grant(:stuff, :other_attr) { true }
        grant(:name) { false }
        self
      end
      @c = c.new
    end

    it 'should return a hash of attributes and actions' do
      @c.granted[:attributes].should_not be_nil
      @c.granted[:actions].should_not be_nil
    end

    it 'should sort returned attributes alphabetically when no attributes are passed in to filter by' do
      @c.granted[:attributes].should == [:other_attr, :stuff]
    end

    it 'should list granted attributes for current_user' do
      @c.granted[:attributes].should =~ [:other_attr, :stuff]
    end

    it 'should list granted attributes and actions for current_user when passed :granted => true' do
      @c.granted(:granted => true)[:attributes].should =~ [:other_attr, :stuff]
      @c.granted(:granted => true)[:actions].should == [:create]
    end

    it 'should list ungranted actions and attributes for current_user when passed false' do
      @c.granted(:granted => false)[:attributes].should =~ [:create, :name, :ungranted_attr]
      @c.granted(:granted => false)[:actions].should =~ [:find, :update, :destroy]
    end

    it 'should recognize arguments as strings' do
      @c.granted('granted' => false)[:attributes].should =~ [:create, :name, :ungranted_attr]
    end

    context 'given a list of attributes or actions' do
      it 'should return a limited list of attributes or actions that are granted' do
        @c.granted(:stuff, :other_attr, :granted => true)[:attributes].should == [:stuff, :other_attr]
        @c.granted(:name, :granted => true)[:attributes].should == []
        @c.granted(:name, :granted => true)[:actions].should == []
        @c.granted(:name, :find, :create, :granted => true)[:actions].should == [:create]
      end

      it 'should return a limited list of attributes or actions that are not granted' do
        @c.granted(:name, :granted => false)[:attributes].should == [:name]
        @c.granted(:name, :find, :granted => false)[:actions].should == [:find]
      end

      it 'should return list of attributes in order it was passed in' do
        @c.granted(:other_attr, :stuff)[:attributes].should == [:other_attr, :stuff]
        @c.granted(:stuff, :other_attr)[:attributes].should == [:stuff, :other_attr]
      end

      it 'should recognize attributes passed in as strings' do
        @c.granted('stuff', 'other_attr', :granted => true)[:attributes].should == [:stuff, :other_attr]
      end
    end

    context 'grant_disabled' do
      before do
        c = new_model_class.instance_eval do
          grant(:stuff, :other_attr) { true }
          grant(:name, :find, :create) { false }
          self
        end

        c.class_eval do
          def grant_disabled?
            true
          end
        end

        @c = c.new
      end

      it 'should list all attributes and actions as granted' do
        @c.granted(:granted => true)[:attributes].should =~ [:name, :other_attr, :stuff, :ungranted_attr, :create]
        @c.granted(:granted => true)[:actions].should =~ [:create, :find, :update, :destroy]
        @c.granted(:name, :granted => true)[:attributes].should == [:name]
      end

      it 'should list no attributes as ungranted' do
        @c.granted(:granted => false).should == {:attributes => [], :actions => []}
        @c.granted(:name, :granted => false).should == {:attributes => [], :actions => []}
      end
    end
  end

  describe '#granted?' do
    before do
      c = new_model_class.instance_eval do
        grant(:stuff, :other_attr, :find) { true }
        grant(:name) { false }
        self
      end
      @c = c.new
    end

    it 'should return true if user is granted permission for passed in attribute or action' do
      @c.granted?(:stuff).should == true
      @c.granted?(:name).should == false
      @c.granted?(:update).should == false
      @c.granted?(:find).should == true
    end

    context 'multiple arguments' do
      it 'should return false when one of the attributes or actions passed in is not granted' do
        @c.granted?(:name, :stuff, :find).should == false
      end

      it 'should return true when all of the attributes and actions passed in are granted' do
        @c.granted?(:stuff, :other_attr, :find).should == true
      end
    end
  end
    
  def verify_standard_callbacks(instance, *succeeding_callbacks)
    verify_callbacks([:create, :update, :destroy, :find], instance, nil, succeeding_callbacks)
  end
  
  def verify_callbacks(all_actions, instance, associated_model, succeeding_callbacks)
    all_actions.each do |action|
      expectation = succeeding_callbacks.include?(action) ? :should_not : :should
      lambda { instance.send(action) }.send(expectation, raise_error(Grant::Error))
    end
  end
  
  def new_model_class
    Class.new(ActiveRecordMock) do
      include Grant::ModelSecurity
    end
  end

end
