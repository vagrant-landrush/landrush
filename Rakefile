require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rubocop/rake_task'
require 'cucumber/rake/task'

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

RuboCop::RakeTask.new

Cucumber::Rake::Task.new(:features)
