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
