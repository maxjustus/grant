Grant
=====

Grant is a Ruby gem and Rails plugin for securing access to your ActiveRecord model objects. It provides a declarative way to specify rules for granting permission to perform CRUD operations on model objects. 

Grant does not allow you to specify which operations are restricted. Instead, it restricts all CRUD operations unless they're explicitly granted to the user. It also restricts adding or removing items to/from has_many and has_and_belongs_to_many associations. Only allowing operations explicitly granted forces you to make conscious security decisions. Grant will not help you make those decisions, but it won't let you forget to.

Installation
============

To install the Grant gem, simply run

  gem install grant
  
To use it with a Rails 3 project or other project using Bundler, add the following line to your Gemfile

  gem 'grant'
  
For your Rails 2.x project, add the following to your environment.rb file

  config.gem 'grant'

Lastly, Grant can also be installed as a Rails plugin
  
  script/plugin install git://github.com/nearinfinity/grant.git

Usage
=====

To enable model security you simply include the Grant::ModelSecurity module in your model class. In the example below you see three grant statements. The first grants find (aka read) permission all the time. The second example grants create, update, and destroy permission when the passed block evaluates to true, which in this case happens when the model is editable by the current user. Similarly, the third grant statement permits additions and removals from the tags association when it's block evaluates to true. A Grant::Error is raised if any grant block evaluates to false or nil.

	class Book < ActiveRecord::Base
	  include Grant::ModelSecurity

	  has_many :tags
  
	  grant(:find)
	  grant(:create, :update, :destroy) { |user, model| model.editable_by_user? user }
	  grant(:add => :tags, :remove => :tags) { |user, model, associated_model| model.editable_by_user? user }

	  def editable_by_user? user
	    user.administrator? || user.has_role?(:editor) 
	  end
	end

The valid actions to pass to a grant statement are :find, :create, :update, :destroy, :add, and :remove. The first four options are passed as symbols while :add and :remove are hash keys to association names they protect. Any number of options can be passed to a single grant statement, which is very useful if each of the actions share the same logic for determining access.

Integration
===========

There may be some instances where you need to perform an action on your model object without Grant stepping in and stopping you. In those cases you can include the Grant::Integration module for help.

  class BooksController < ApplicationController
    include Grant::Integration
    
    def update
      book = Book.find(params[:id])
      without_grant { book.update_attributes(params[:book]) } # Grant is disabled for the entire block
    end
  end

Copyright (c) 2010 Near Infinity Corporation, released under the MIT license
