# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
 
require 'grant/version'
 
Gem::Specification.new do |s|
  s.name        = "grant"
  s.version     = Grant::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jeff Kunkle", "Matt Wizeman"]
  s.homepage    = "http://github.com/nearinfinity/grant"
  s.summary     = "Guaranteed security for your ActiveRecord model objects"
  s.description = "Grant allows you to declaratively specify rules for granting permission to allow CRUD operations on model objects"
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.add_development_dependency "rspec"
 
  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.rdoc)
  s.require_path = 'lib'
end