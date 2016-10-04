require 'bundler/gem_tasks'
require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rubocop/rake_task'
require 'cucumber/rake/task'
require 'fileutils'

CLOBBER.include('pkg')
CLEAN.include('build')

task :init do
  FileUtils.mkdir_p 'build'
end
task features: :init

# Default test task
desc 'Run all unit tests'
Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
  t.libs << 'test'
end

# Cucumber acceptance test task
Cucumber::Rake::Task.new(:features)
task features: :init

task default: [
  :rubocop,
  :test
]

task :generate_diagrams do
  sh 'cd doc; seqdiag --fontmap=support/seqdiag.fontmap -Tsvg vagrant_dns_without_landrush.diag'
end

RuboCop::RakeTask.new
