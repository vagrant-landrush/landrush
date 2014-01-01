require 'bundler/gem_tasks'

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
  t.libs << 'test'
end

task :default => :test

task :generate_diagrams do
  sh "cd doc; seqdiag --fontmap=support/seqdiag.fontmap -Tsvg vagrant_dns_without_landrush.diag"
end
