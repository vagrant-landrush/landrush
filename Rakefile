require 'bundler/gem_tasks'
require 'rake'
require 'rake/testtask'
require 'rake/clean'
require 'rubocop/rake_task'
require 'cucumber/rake/task'
require 'fileutils'
require 'asciidoctor'

CLOBBER.include('pkg')
CLEAN.include('build')

task :init do
  # general build directory
  FileUtils.mkdir_p 'build'
  # Vagrant home directory for integration tests
  FileUtils.mkdir_p 'build/vagrant.d'
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

desc 'Render Asciidoc into HTML'
adoc_files = Rake::FileList['**/*.adoc']
task html: adoc_files.ext('.html')
rule '.html' => '.adoc' do |t|
  FileUtils.mkdir_p 'build/html'
  Asciidoctor.convert_file t.source, to_dir: 'build/html'
end

task default: [
  :rubocop,
  :test
]

task :generate_diagrams do
  sh 'cd doc; seqdiag --fontmap=support/seqdiag.fontmap -Tsvg vagrant_dns_without_landrush.diag'
end

RuboCop::RakeTask.new
