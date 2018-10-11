source 'http://rubygems.org'

gem 'rspec', '>= 2.0', '< 4.0'
gem 'rspec-support', '>= 3.1', '< 4.0'
gem 'thor', '~> 0.19.1'
gem 'ruby-plsql', '~> 0.5'
gem 'nokogiri', '~> 1.8'

group :development do
  gem 'juwelier', '~> 2.0'
  gem 'rspec_junit_formatter', '~> 0'
end

group :test, :development do
  gem 'rake', '>= 10.0', '< 12.0'

  platforms :ruby, :mswin, :mingw do
    gem 'ruby-oci8', '~> 2.1'
  end
end
