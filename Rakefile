require 'rake'
require 'rake/rdoctask'
gem "rspec", "1.2.9"
require 'spec'
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'

desc 'Default: run specs'
task :default => :spec

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
  t.spec_files = FileList["spec/**/*_spec.rb"]
end

desc "Run all specs in spec directory with RCov"
Spec::Rake::SpecTask.new(:rcov) do |t|
  t.spec_opts = ['--options', "\"#{File.dirname(__FILE__)}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = lambda do
    IO.readlines(File.dirname(__FILE__) + "/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
  end
end

desc 'Generate documentation for the grant plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'Grant'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
