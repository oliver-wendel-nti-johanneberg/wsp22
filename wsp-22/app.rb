require 'sinatra'
require 'slim'
require 'sqlite3'

enable :sessions

get('/') do
slim(:start)
end