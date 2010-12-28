$:.unshift File.expand_path("../lib", __FILE__)

require 'rake'
require 'rake/rdoctask'
require 'rspec/core/rake_task'

desc 'Default: run specs'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w(-fs --color)
end

desc "Run specs with RCov"
RSpec::Core::RakeTask.new(:rcov) do |t|
  t.rspec_opts = %w(-fs --color)
  t.rcov = true
  t.rcov_opts = %w(--exclude "spec/*,gems/*")
end

desc 'Generate documentation for the grant plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Grant'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.markdown')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

task :build do
  system "gem build grant.gemspec"
end
 
task :release => :build do
  system "gem push grant-#{Grant::VERSION}"
end