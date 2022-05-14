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

    def check_password(password_digest, password)
        return BCrypt::Password.new(password_digest) == password
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

    def update_comp(name, date, winner, p2, p3, p4, p5, p6, p7, p8, id)
        db = connect_db("db/horse_data.db")
        db.execute("UPDATE competitions SET name=?,date=?,winner=?,p2=?,p3=?,p4=?,p5=?,p6=?,p7=?,p8=? WHERE id = ?", name, date, winner, p2, p3, p4, p5, p6, p7, p8, id)
        db.execute("DELETE FROM HCR WHERE competition_id = ?", id)
        db.results_as_hash = false
        comp_r = db.execute("SELECT id, winner, p2, p3, p4, p5, p6, p7, p8 FROM Competitions WHERE id = ?", id)
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


    def horse_id_f(id)
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT * FROM Horses WHERE id = ?", id)
    end

    def user_id_f(id)
        db = connect_db("db/horse_data.db")
        user_result = db.execute("SELECT * FROM User WHERE id = ?", id)
    end

    def user_name_f(username)
        db = connect_db("db/horse_data.db")
        user_result = db.execute("SELECT id, password FROM User WHERE username = ?", username)
    end

    def delete_comp(id)
        db = connect_db("db/horse_data.db")
        db.execute("DELETE FROM Competitions WHERE id = ?", id)
        db.execute("DELETE FROM HCR WHERE competition_id = ?", id)
    end

    def comp_id_f(id)
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT * FROM Competitions WHERE id = ?", id)
    end

    def horse_names
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT name FROM Horses")
    end

    def end_season()
        db = connect_db("db/horse_data.db")
        season_winner_horses = db.execute("SELECT id, titles FROM Horses WHERE name = (SELECT name FROM v_StandingsHorses WHERE norank = 1)")
        season_winner_owners = db.execute("SELECT id, titles FROM User WHERE username = (SELECT username FROM v_StandingsOwners WHERE norank = 1)")
        h_titles = season_winner_horses.first["titles"] + 1
        o_titles = season_winner_owners.first["titles"] + 1
        db.execute("UPDATE Horses SET titles=? WHERE id = ?", h_titles, season_winner_horses.first["id"])
        db.execute("UPDATE User SET titles=? WHERE id = ?", o_titles, season_winner_owners.first["id"])
        season_result_owners = db.execute("SELECT username, wins, losses FROM v_StandingsOwners")
        i = 0
        while i < season_result_owners.length  
            user = db.execute("SELECT * FROM User WHERE username = ?", season_result_owners[i]["username"])
            t_wins = season_result_owners[i]["wins"] + user.first["t_wins"] 
            t_losses = season_result_owners[i]["losses"] + user.first["t_losses"]
            db.execute("UPDATE User SET t_wins=?,t_losses=? WHERE id = ?", t_wins, t_losses, user.first["id"])
            i +=1
        end
        db.execute("DELETE FROM Competitions")
        db.execute("DELETE FROM HCR")
    end

    def s_horses
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT * FROM v_StandingsHorses")
    end
    
    def s_horses_limited
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT * FROM v_StandingsHorses LIMIT 3;")
    end

    def s_owners
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT * FROM v_StandingsOwners")
    end

    def s_owners_limited
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT * FROM v_StandingsOwners LIMIT 3;")
    end

    def horse_result(user_id) 
        db = connect_db("db/horse_data.db")
        db.execute("SELECT id, Horses.name, weight, height, titles, wins, losses, points, norank FROM Horses INNER JOIN v_StandingsHorses on v_StandingsHorses.name = Horses.name WHERE Horses.owner_id = ?", user_id)
    end

    def user_info(id, username)
        db = connect_db("db/horse_data.db")
        horse_info = db.execute("SELECT * FROM Horses WHERE owner_id = ?", id)
        user_result = db.execute("SELECT * FROM User WHERE id = ?", id)
        season_result = db.execute("SELECT (count(win)-sum(win)) AS t_losses ,sum(points) AS t_points, sum(win) AS t_wins FROM HCR inner join Horses on Horses.id = HCR.horse_id WHERE Horses.owner_id = ?", id)
        rank = db.execute("SELECT norank FROM v_StandingsOwners WHERE username = ?", username) 
        n_horses = db.execute("SELECT COUNT(id) AS n_horses FROM Horses WHERE owner_id = ?", id)
        return [horse_info, user_result, season_result, rank, n_horses]
    end

    def new_horse(owner_id, name, weight, height, titles)
        db = SQLite3::Database.new("db/horse_data.db")
        db.results_as_hash = false
        db.execute("INSERT INTO Horses (name, weight, height, titles, owner_id) VALUES (?,?,?,?,?)", name, weight, height, titles, owner_id)
    end

    def delete_horse(id)
        db = connect_db("db/horse_data.db")
        db.execute("DELETE FROM Horses WHERE id = ?", id)
    end

    def update_horse(id, name, weight, height)
        db = connect_db("db/horse_data.db")
        db.execute("UPDATE Horses SET name=?,weight=?,height=? WHERE id = ?", name, weight, height, id)
    end

    def check_empty(array)
        output = false
        i = 0
        while i < array.length
            if array[i].empty? == true
                output = true
            end
            i += 1
        end
        p "Checking"
        p output
        return output
    end

    def create_password(password)
        return BCrypt::Password.create(password)
    end

    def check_if_logged(username)
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT id FROM User WHERE username = ?", username)
    end

    def new_user(username, password_digest, role, t_wins, t_losses, titles)
        db = connect_db("db/horse_data.db")
        db.execute("INSERT INTO User (username, password, role, t_wins, t_losses, titles) VALUES (?,?,?,?,?,?)", username, password_digest, role, t_wins, t_losses, titles)
    end

    def horse_owner_f(id)
        db = connect_db("db/horse_data.db")
        return db.execute("SELECT owner_id FROM Horses WHERE id = ?", id)
    end
    

end
