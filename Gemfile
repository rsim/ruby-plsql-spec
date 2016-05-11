source 'http://rubygems.org'

gem 'rspec', '>= 2.0', '< 4.0'
gem 'rspec-support', '>= 3.1', '< 4.0'
gem 'thor', '~> 0.19.1'
gem 'ruby-plsql', '~> 0.5.0'
gem 'nokogiri', '~> 1.6.0'

group :development do
  gem 'jeweler', '~> 2.0.1'

  platforms :ruby, :mswin, :mingw do
    gem 'ruby-oci8', '~> 2.1'
  end
  # gem 'ruby-oci8', :git => 'git://github.com/kubo/ruby-oci8.git', :platforms => :mri
  gem 'rspec_junit_formatter'
end

group :test do
  gem 'rake',  '>= 10.0'
end
