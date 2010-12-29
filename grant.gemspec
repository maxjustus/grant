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
  s.summary     = "Conscious security constraints for your ActiveRecord model objects"
  s.description = "Grant is a Ruby gem and Rails plugin that forces you to make explicit security decisions about the operations performed on your ActiveRecord models."
 
  s.required_rubygems_version = ">= 1.3.6"
 
  s.add_development_dependency "rspec"
 
  s.files        = Dir.glob("{lib}/**/*") + %w(LICENSE README.rdoc)
  s.test_files   = Dir.glob("{spec}/**/*")
  s.require_path = 'lib'
end