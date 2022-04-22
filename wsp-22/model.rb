
def connect_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

def error_messege(string)
    @message = string
    p @message
    return @message
end