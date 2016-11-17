source 'https://rubygems.org'

# Vagrant's special group
group :plugins do
  gemspec
end

group :development do
  gem 'vagrant',
      git: 'https://github.com/mitchellh/vagrant.git',
      ref: 'v1.8.6'
  gem 'rake', '~> 10'
  gem 'rubocop', '~> 0.38.0'
  gem 'byebug'
  gem 'mocha'
  gem 'minitest'
  gem 'cucumber', '~> 2.1'
  gem 'aruba', '~> 0.13'
  gem 'komenda', '~> 0.1.6'
  gem 'guard-rake'
  gem 'guard-livereload', '~> 2.5', require: false
  gem 'asciidoctor'
end
