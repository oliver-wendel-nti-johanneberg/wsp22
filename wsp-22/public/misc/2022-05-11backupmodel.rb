module Model

    # Connects and imports database of a specified path and sets the results as hash
    #
    # @return [Database] containing the data of the database with the specified path
    def connect_db(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db
    end

    # Checks if the time between the users last three logins is more than 30 seconds apart if so returns the time
    #
    # @return [Integer] The current time 
    # @return [false] if the time between the users last three logins is more than 30 seconds
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

    # Checks if the current time is 30 seconds past when the cooldown was issued
    #
    # @return [true] if the time since cooldown is more than 30 seconds
    # @return [false] if the time since cooldown is less than 30 seconds
    def password_cooldown_counter(cooldown)
        if Time.now.to_i - cooldown > 30
            return true
        else
            return false
        end
    end

    # Returns all data from table horses as a hash
    #
    # @return [hash] all data from horses
    #   * :id [Integer] The ID of the horse
    #   * :name [String] The name of the horse
    #   * :weight [String] The date of the horse
    #   * :height [String] The height of the horse
    #   * :titles [Integer] The number of titles of the horse
    #   * :owner_id [Integer] The id of the horses owner
    def horses_f
        db = connect_db("db/horse_data.db")
        db.results_as_hash = true
        result = db.execute("SELECT * FROM Horses")
        return result
    end

    # Returns all data from table competitions as a hash
    #
    # @return [hash] all data from competitions
    #   * :id [Integer] The ID of the horse
    #   * :name [String] The name of the horse
    #   * :date [String] The date of the horse
    #   * :winner [String] The name of the winner of the competition
    #   * :p2 [String] The name of the horse in p2
    #   * :p3 [String] The name of the horse in p3
    #   * :p4 [String] The name of the horse in p4
    #   * :p5 [String] The name of the horse in p5
    #   * :p6 [String] The name of the horse in p6
    #   * :p7 [String] The name of the horse in p7
    #   * :p8 [String] The name of the horse in p8
    def competitions_f
        db = connect_db("db/horse_data.db")
        result = db.execute("SELECT * FROM Competitions")
        return result
    end

    def new_comp(name, date, winner, p2, p3, p4, p5, p6, p7, p8)
        db = connect_db("db/horse_data.db")
        db.results_as_hash = false
        db.execute("INSERT INTO Competitions (name, date, winner, p2, p3, p4, p5, p6, p7, p8) VALUES (?,?,?,?,?,?,?,?,?,?)", name, date, winner, p2, p3, p4, p5, p6, p7, p8)
        comp_r = db.execute("SELECT id, winner, p2, p3, p4, p5, p6, p7, p8 FROM Competitions WHERE id = (SELECT MAX (id) FROM Competitions)")
        x = 1
        while x < comp_r[0].length
            horse_id = db.execute("SELECT id FROM Horses WHERE name = ?", comp_r[0][x])
            competition_id = comp_r[0][0]
            pos_id = x
            if pos_id == 1
                win = 1
            else
                win = 0
            end
            points = db.execute("SELECT pts FROM Points WHERE id = ?", pos_id)
            db.execute("INSERT INTO HCR (horse_id, competition_id, pos_id, points, win) VALUES (?,?,?,?,?)", horse_id, competition_id, pos_id, points, win)
            x += 1
        end
    end

    def horse_id(id)
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT id FROM Horses WHERE name = ?", id)
    end

    def delete_comp(id)
        db = connect_db("db/horse_data.db")
        db.execute("DELETE FROM Competitions WHERE id = ?", id)
        db.execute("DELETE FROM HCR WHERE competition_id = ?", id)
    end

    def comp_id(id)
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT * FROM Competitions WHERE id = ?", id)
    end

    def horse_names
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT name FROM Horses")
    end

end