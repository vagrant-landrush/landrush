require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'

# Immediately sync all stdout
$stdout.sync = true
$stderr.sync = true

# Change to the directory of this file
Dir.chdir(File.expand_path('../', __FILE__))

# Rubocop
RuboCop::RakeTask.new

# Tests
Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
  t.libs << 'test'
end

task default: [
  :rubocop,
  :test
]

task :generate_diagrams do
  sh 'cd doc; seqdiag --fontmap=support/seqdiag.fontmap -Tsvg vagrant_dns_without_landrush.diag'
end
