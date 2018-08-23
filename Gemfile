source 'https://rubygems.org'

# Vagrant's special group
group :plugins do
  gemspec
end

group :development do
  gem 'aruba', '~> 0.13'
  gem 'asciidoctor'
  gem 'byebug'
  gem 'cucumber', '~> 2.1'
  gem 'guard-livereload', '~> 2.5', require: false
  gem 'guard-rake'
  gem 'komenda', '~> 0.1.6'
  gem 'minitest'
  gem 'mocha'
  gem 'rake', '~> 10'
  gem 'rubocop'
  gem 'vagrant',
      git: 'https://github.com/mitchellh/vagrant.git',
      ref: 'v2.1.2'
end
