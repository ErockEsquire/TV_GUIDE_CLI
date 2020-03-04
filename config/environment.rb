require "bundler/setup"
require "sinatra/activerecord"
Bundler.require


ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: 'db/development.db')
require_all 'app'

ActiveRecord::Base.logger = nil