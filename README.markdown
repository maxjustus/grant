Grant
=====

Grant is an easy to use Ruby on Rails plugin for securing access to your Rails model objects. It provides a simple way to declaratively specify rules for granting a user permission to perform CRUD operations on model objects. 

Design Philosophy
=================

When designing the model security portion of Grant, we decided that it shouldn't be used to specify which operations were restricted. Instead, it restricts all CRUD operations and unless they're explicitly granted to the user. It also restricts adding or removing items from has_many and has_and_belongs_to_many associations. Only allowing operations explicitly granted forces you to make conscious security decisions.

Examples
========

The following example demonstrates model security. To enable model security you simply include the Grant::ModelSecurity module in your model class. In this example you see three grant statements. The first grants find (aka read) permission to everyone. The second example grants create, update, and destroy permission when the passed block evaluates to true, which in this case happens when the model is editable by the current user. Similarly, the third grant statement permits additions and removals from the tags association when it's block evaluates to true. A Grant::Error is raised if any grant block evaluates to false or nil.

	class Book < ActiveRecord::Base
	  include Grant::ModelSecurity

	  has_many :tags
  
	  grant(:find) { true }
	  grant(:create, :update, :destroy) { |user, model| model.editable_by_user? user }
	  grant(:add => :tags, :remove => :tags) { |user, model, associated_model| model.editable_by_user? user }

	  def editable_by_user? user
	    user.administrator? || user.has_role?(:editor) 
	  end
	end

There's a lot more to the grant statement than shown in the above example. For instance, you can have multiple grant statements for the same action. Ultimate permission to perform the action will not be granted unless all grant blocks evaluate to true.

Copyright (c) 2010 Near Infinity Corporation, released under the MIT license
