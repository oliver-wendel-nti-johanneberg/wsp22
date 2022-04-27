module Model

    def connect_db(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db
    end

    def validate_digits(input)

        answer = input.scan(/\D/).empty? 

        return answer
    end

    def password_cooldown_detection(timearray)
        if timearray.length == 3
            if timearray[2] - timearray[0] < 30
                return Time.now.to_i
            else
                return false
            end
        end

        return false
    end

    def password_cooldown_counter(cooldown)
        if Time.now.to_i - cooldown > 30
            return true
        else
            return false
        end
    end

    def users_f
        db = connect_db("db/horse_data.db")
        db.results_as_hash = true
        result = db.execute("SELECT * FROM User")
        return result
    end

    def horses_f
        db = connect_db("db/horse_data.db")
        db.results_as_hash = true
        result = db.execute("SELECT * FROM Horses")
        return result
    end

    def competitions_f
        db = connect_db("db/horse_data.db")
        db.results_as_hash = true
        result = db.execute("SELECT * FROM Competitions")
        return result
    end

    def error
        return session[:error_messege]
    end
end