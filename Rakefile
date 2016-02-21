require 'bundler/gem_tasks'
require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rubocop/rake_task'
require 'cucumber/rake/task'

CLOBBER.include('pkg/*')

# Default test task
Rake::TestTask.new do |t|
  t.pattern = 'test/**/*_test.rb'
  t.libs << 'test'
end

targets = []
Dir.glob('./test/**/*_test.rb').each do |test_file|
  targets << test_file
end

targets.each do |target|
  target_name = 'test-' + File.basename(target).chomp('_test.rb')
  Rake::TestTask.new(target_name.to_sym) do |t|
    t.pattern = target.to_s
    t.libs << 'test'
  end
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
