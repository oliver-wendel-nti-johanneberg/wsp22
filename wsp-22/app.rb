require 'sinatra'
require 'slim'
require 'sqlite3'

enable :sessions

get('/') do
    db = SQLite3::Database.new("db/horse_data.db")
    db.results_as_hash = true
    r_competitions = db.execute("SELECT * FROM Competitions")

    slim(:start, locals:{competitions:r_competitions})
end

get('/standings') do
slim(:"standings/standings")
end