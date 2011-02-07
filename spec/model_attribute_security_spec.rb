require File.dirname(__FILE__) + '/spec_helper'
require 'grant'

describe Grant::ModelAttributeSecurity do

  before(:each) do
    Grant::User.current_user = (Class.new do
      def id; 1 end
      def auth_level; 10 end
    end).new
  end

  describe 'module include' do
    it 'should establish failing ActiveRecord callback for before_save when included' do
      verify_standard_callbacks(new_model_class.new)
    end
  end

  describe '#granted_attributes' do
    before do
      c = new_model_class.instance_eval do
        grant_attributes(:stuff, :other_attr) { true }
        grant_attributes(:name) { false }
        self
      end
      @c = c.new
    end

    it 'should list granted attributes for current_user' do
      @c.granted_attributes.should == [:stuff, :other_attr]
    end

    it 'should list granted attributes for current_user when passed :granted => true' do
      @c.granted_attributes(:granted => true).should == [:stuff, :other_attr]
    end

    it 'should list ungranted attributes for current_user when passed false' do
      @c.granted_attributes(:granted => false).should == [:name, :ungranted_attr]
    end

    it 'should recognize arguments as strings' do
      @c.granted_attributes('granted' => false).should == [:name, :ungranted_attr]
    end

    context 'given a list of attributes' do
      it 'should return a limited list of attributes that are granted' do
        @c.granted_attributes(:stuff, :other_attr, :granted => true).should == [:stuff, :other_attr]
        @c.granted_attributes(:name, :granted => true).should == []
      end

      it 'should return a limited list of attributes that are not granted' do
        @c.granted_attributes(:name, :granted => false).should == [:name]
      end

      it 'should return list in order it was passed in' do
        @c.granted_attributes(:other_attr, :stuff).should == [:other_attr, :stuff]
      end

      it 'should recognize attributes passed in as strings' do
        @c.granted_attributes('stuff', 'other_attr', :granted => true).should == [:stuff, :other_attr]
      end
    end

    context 'grant_disabled' do
      before do
        c = new_model_class.instance_eval do
          grant_attributes(:stuff, :other_attr) { true }
          grant_attributes(:name) { false }
          self
        end

        c.class_eval do
          def grant_disabled?
            true
          end
        end

        @c = c.new
      end

      it 'should list all attributes as granted' do
        @c.granted_attributes(:granted => true).should == [:name, :stuff, :other_attr, :ungranted_attr]
        @c.granted_attributes(:name, :granted => true).should == [:name]
      end

      it 'should list no attributes as ungranted' do
        @c.granted_attributes(:granted => false).should == []
        @c.granted_attributes(:name, :granted => false).should == []
      end
    end
  end

  describe '#granted_attribute?' do
    before do
      c = new_model_class.instance_eval do
        grant_attributes(:stuff, :other_attr) { true }
        grant_attributes(:name) { false }
        self
      end
      @c = c.new
    end

    it 'should return true if user is granted permission for passed in attribute' do
      @c.granted_attributes?(:stuff).should == true
      @c.granted_attributes?(:name).should == false
    end

    context 'multiple arguments' do
      it 'should return false when one of the attributes passed in is not granted' do
        @c.granted_attributes?(:name, :stuff).should == false
      end

      it 'should return true when all of the attributes passed in are granted' do
        @c.granted_attributes?(:stuff, :other_attr).should == true
      end
    end
  end

  describe '#grant_attributes' do
    it 'should allow update of attributes specified using grant_attributes' do
      c = new_model_class.instance_eval do
        grant_attributes(:name) { true }
        grant_attributes(:stuff, :other_attr) { true }
        self
      end
      verify_standard_callbacks(c.new, :create, :update)
    end

    it 'should pass current_user and model to block' do
      c = new_model_class.instance_eval do
        grant_attributes(:name, :stuff, :other_attr) {|user, model| user.auth_level == 10 && model.name == 'thing' }
        self
      end

      verify_standard_callbacks(c.new, :create, :update)
    end

    it 'should be restrictive rather then permissive' do
      c = new_model_class.instance_eval do
        grant_attributes(:name) { true }
        self
      end
      verify_standard_callbacks(c.new)
    end

    it 'should respect grant_disabled' do
      c = new_model_class.instance_eval do
        grant_attributes(:name) { false }
        self
      end

      c.class_eval do
        def grant_disabled?
          true
        end
      end

      verify_standard_callbacks(c.new, :create, :update)
    end

    it 'should allow update if nothing is changed' do
      c = new_model_class.instance_eval do
        grant_attributes(:name) { false }
        grant_attributes(:stuff, :other_attr) { true }

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
        grant_attributes(:name) { false }
        grant_attributes(:stuff, :other_attr) { true }
        self
      end

      verify_standard_callbacks(c.new)
    end

    it 'should deny update of attributes when nil is used as the return value for block' do
      c = new_model_class.instance_eval do
        grant_attributes(:name, :stuff, :other_attr) { true }
        grant_attributes(:name) { nil }
        self
      end

      verify_standard_callbacks(c.new)
    end

    it 'should allow multiple attributes to be specified with one grant_attributes statement' do
      c = new_model_class.instance_eval do
        grant_attributes(:name, :stuff, :other_attr) { true }
        self
      end
      verify_standard_callbacks(c.new, :create, :update)

      c = new_model_class.instance_eval do
        grant_attributes(:name, :stuff) { false }
        grant_attributes(:other_attr) { true }
        self
      end
      verify_standard_callbacks(c.new)
    end
  end

  describe 'with model_security' do
    it 'should deny method use when not granted' do
      c = new_model_class.instance_eval do
        include Grant::ModelSecurity
        grant_attributes(:name, :stuff, :other_attr) { true }
        self
      end

      verify_standard_callbacks(c.new)
    end

    it 'should allow method use when granted' do
      c = new_model_class.instance_eval do
        include Grant::ModelSecurity
        grant(:create) { true }
        grant_attributes(:name, :stuff, :other_attr) { true }
        self
      end

      verify_standard_callbacks(c.new, :create)
    end

    it 'should deny attribute change when not granted' do
      c = new_model_class.instance_eval do
        include Grant::ModelSecurity
        grant(:create, :update) { true }
        grant_attributes(:name) { true }
        grant_attributes(:stuff) { false }
        self
      end

      verify_standard_callbacks(c.new)
    end

    it 'should deny method use when nothing granted' do
      c = new_model_class.instance_eval do
        include Grant::ModelSecurity
        self
      end

      verify_standard_callbacks(c.new)
    end
  end

  def verify_standard_callbacks(instance, *succeeding_callbacks)
    verify_callbacks([:create, :update], instance, nil, succeeding_callbacks)
  end

  def verify_callbacks(all_actions, instance, associated_model, succeeding_callbacks)
    all_actions.each do |action|
      expectation = succeeding_callbacks.include?(action) ? :should_not : :should
      lambda { instance.send(action) }.send(expectation, raise_error(Grant::Error))
    end
  end

  def new_model_class(with_model_security = false)
    Class.new(ActiveRecordMock) do
      include Grant::ModelAttributeSecurity
    end
  end

end
