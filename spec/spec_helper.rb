require "rubygems"
require "bundler"
Bundler.setup(:default)

$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rspec'
require 'nokogiri'

require 'ruby-plsql-spec'

DATABASE_NAME = ENV['DATABASE_NAME'] || 'orcl'
DATABASE_SERVICE_NAME = (defined?(JRUBY_VERSION) ? "/" : "") +
                        (ENV['DATABASE_SERVICE_NAME'] || DATABASE_NAME)
DATABASE_HOST = ENV['DATABASE_HOST'] || 'localhost'
DATABASE_PORT = (ENV['DATABASE_PORT'] || 1521).to_i
DATABASE_USER = ENV['DATABASE_USER'] || 'hr'
DATABASE_PASSWORD = ENV['DATABASE_PASSWORD'] || 'hr'

CONNECTION_PARAMS = {
  :username => DATABASE_USER,
  :password => DATABASE_PASSWORD,
  :database => DATABASE_SERVICE_NAME
}
CONNECTION_PARAMS[:host] = DATABASE_HOST if defined?(DATABASE_HOST)
CONNECTION_PARAMS[:port] = DATABASE_PORT if defined?(DATABASE_PORT)

RSpec.configure do |config|
  # taken from thor specs
  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure 
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end
  alias :silence :capture

  def source_root
    File.join(File.dirname(__FILE__), 'fixtures')
  end

  def destination_root
    File.join(File.dirname(__FILE__), 'sandbox')
  end

end

# set default time zone in TZ environment variable
# which will be used to set session time zone
ENV['TZ'] ||= 'Europe/Riga'
# ENV['TZ'] ||= 'UTC'
