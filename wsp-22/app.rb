require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions

include Model

# Checks if user is logged in (Has role admin(2) or role owner(1)). If user is not logged in an error messege is displayed if user tries to request a route not specified below.
#
before do 
    whitelisted_routes_routes = ['/', '/standings', '/error', '/register', '/log_in', '/user/new', '/register_confirm', '/horses/']
    i = 0
    access = false
    while i < whitelisted_routes_routes.length
        if request.path_info == whitelisted_routes_routes[i]
            access = true
        end 
        i += 1
    end
    if (session[:role] != 1 && session[:role] != 2) && request.path_info.include?("/horses/") == true || request.path_info.include?("/competitions/") == true
        access = true
    end
    if (session[:role] == 1 || session[:role] == 2)
        access = true
    end
    if access == false
        session[:error_messege] = "Du har inte behörighet till denna sidan"
        redirect('/error')
    end
end


# Displays start page, and all competitions, if user is admin the (/competitions/new) form is displayed 
#
# @see Model#competitions_f
# @see Model#horses_f
# @see Model#connect_db
get('/') do
    db = connect_db("db/horse_data.db")
    r_competitions = competitions_f
    if r_competitions.empty?
        db = SQLite3::Database.new("db/horse_data.db")
        db.results_as_hash = true
        horses = horses_f
        name = "placeholder"
        date = "placeholder_date"
        winner = horses[0]["name"]
        p2 = horses[1]["name"]
        p3 = horses[2]["name"]
        p4 = horses[3]["name"]
        p5 = horses[4]["name"]
        p6 = horses[5]["name"]
        p7 = horses[6]["name"]
        p8 = horses[7]["name"]
        db.execute("INSERT INTO Competitions (name, date, winner, p2, p3, p4, p5, p6, p7, p8) VALUES (?,?,?,?,?,?,?,?,?,?)", name, date, winner, p2, p3, p4, p5, p6, p7, p8)
        db.results_as_hash = false
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
        redirect("/")
    end

    r_user = db.execute("SELECT * FROM User WHERE id = ?", session[:user_id]).first
    if r_user == nil
        r_user = {
            "username" => "Not logged in"
        }
        session[:ranking] = 0
        session[:n_horses] = 0
    end

    r_competitions = competitions_f
    h_names = db.execute("SELECT name FROM Horses")
    v_standingHorses = db.execute("SELECT * FROM v_StandingsHorses LIMIT 3;")
    v_standingOwners = db.execute("SELECT * FROM v_StandingsOwners LIMIT 3;")
    slim(:start, locals:{competitions:r_competitions, horse_names:h_names, standing_horses:v_standingHorses, standing_owners:v_standingOwners, user:r_user})
end


# Checks if user is admin and if any fields in the form is empty if so an error messege is displayed.
#
# @param [String] place_comp, The place/name of the competition
# @param [String] date_comp, The specified date of the competition  
before('/competitions') do
    if session[:role] != 2 
        session[:error_messege] = "Du har inte behörighet för att göra detta"
        redirect('/error')
    end
    if params[:place_comp].empty? || params[:date_comp].empty?
        session[:error_messege] = "Fel input"
        redirect('/error')
    end
end


# Creates a new competition and redirects to '/'
#
# @param [String] place_comp, The place/name of the competition
# @param [String] date_comp, The specified date of the competition  
# @param [String] select_winner, The name of the horse that was selected as the winner 
# @param [String] select_2nd, The name of the horse that was selected as coming 2nd
# @param [String] select_3nd, The name of the horse that was selected as coming 3rd
# @param [String] select_4nd, The name of the horse that was selected as coming 4th
# @param [String] select_5nd, The name of the horse that was selected as coming 5th
# @param [String] select_6nd, The name of the horse that was selected as coming 6th
# @param [String] select_7nd, The name of the horse that was selected as coming 7th
# @param [String] select_8nd, The name of the horse that was selected as coming 8th
post('/competitions') do
    place = params[:place_comp]
    date = params[:date_comp]
    winner = params[:select_winner]
    select_2nd = params[:select_2nd]
    select_3rd = params[:select_3rd]
    select_4th = params[:select_4th]
    select_5th = params[:select_5th]
    select_6th = params[:select_6th]
    select_7th = params[:select_7th]
    select_8th = params[:select_8th]
    db = SQLite3::Database.new("db/horse_data.db")
    db.results_as_hash = false
    db.execute("INSERT INTO Competitions (name, date, winner, p2, p3, p4, p5, p6, p7, p8) VALUES (?,?,?,?,?,?,?,?,?,?)", place, date, winner, select_2nd, select_3rd, select_4th, select_5th, select_6th, select_7th, select_8th)
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

    redirect('/')
end


# Checks if user is admin otherwise redirects to '/error' and displays a specified error messege
#
before('/competitions/:id/delete') do
    if session[:role] != 2 
        session[:error_messege] = "Du har inte behörighet för att göra detta"
        redirect('/error')
    end
end

# Deletes a competition and the related Horse-competitions-relations table with the specified table and then redirects to '/'
#
# @see Model#connect_db
post('/competitions/:id/delete') do
    id = params[:id].to_i
    db = connect_db("db/horse_data.db")
    db.execute("DELETE FROM Competitions WHERE id = ?", id)
    db.execute("DELETE FROM HCR WHERE competition_id = ?", id)
    redirect('/')
end

# Checks if user is admin otherwise redirects to '/error' and displays a specified error messege
#
before('/competitions/:id/edit') do
    if session[:role] != 2 
        session[:error_messege] = "Du har inte behörighet för att göra detta"
        redirect('/error')
    end
end

# Displays the edit form for a specified competition
#
# @param [Integer] id, The id of the competition
#
# @see Model#connect_db
get('/competitions/:id/edit') do
    id = params[:id].to_i
    db = connect_db("db/horse_data.db")
    e_result = db.execute("SELECT * FROM Competitions WHERE id = ?", id)
    h_names = db.execute("SELECT name FROM Horses")
    slim(:"/competitions/edit",locals:{edit_comp:e_result, horse_names:h_names})
end

# Checks if user is admin and if any fields are empty otherwise redirects to '/error' and displays a specified error messege
#
# @param [String] place_comp, The place/name of the competition
# @param [String] date_comp, The specified date of the competition  
before('/competitions/:id/update') do
    if session[:role] != 2 
        session[:error_messege] = "Du har inte behörighet för att göra detta"
        redirect('/error')
    end
    if params[:place_comp].empty? || params[:date_comp].empty?
        session[:error_messege] = "Fel input"
        redirect('/error')
    end
end

# Updates a specified competition and the related Horse-competitions-relations table and then redirects to '/'
#
# @param [Integer] id, The id of the competition
# @param [String] place_comp, The place/name of the competition
# @param [String] date_comp, The specified date of the competition  
# @param [String] select_winner, The name of the horse that was selected as the winner 
# @param [String] select_2nd, The name of the horse that was selected as coming 2nd
# @param [String] select_3nd, The name of the horse that was selected as coming 3rd
# @param [String] select_4nd, The name of the horse that was selected as coming 4th
# @param [String] select_5nd, The name of the horse that was selected as coming 5th
# @param [String] select_6nd, The name of the horse that was selected as coming 6th
# @param [String] select_7nd, The name of the horse that was selected as coming 7th
# @param [String] select_8nd, The name of the horse that was selected as coming 8th
#
# @see Model#connect_db
post('/competitions/:id/update') do
    id = params[:id]
    place = params[:place_comp]
    date = params[:date_comp]
    winner = params[:select_winner]
    select_2nd = params[:select_2nd]
    select_3rd = params[:select_3rd]
    select_4th = params[:select_4th]
    select_5th = params[:select_5th]
    select_6th = params[:select_6th]
    select_7th = params[:select_7th]
    select_8th = params[:select_8th]
    db = connect_db("db/horse_data.db")
    db.execute("UPDATE competitions SET name=?,date=?,winner=?,p2=?,p3=?,p4=?,p5=?,p6=?,p7=?,p8=? WHERE id = ?", place, date, winner, select_2nd, select_3rd, select_4th, select_5th, select_6th, select_7th, select_8th, id)
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

    redirect('/')
end

# Shows a competition with a specified id
#
# @param [Integer] id, The id of the competition
#
# @see Model#connect_db
get('/competitions/:id') do
    db = connect_db("db/horse_data.db")
    id = params[:id].to_i
    comp_result = db.execute("SELECT * FROM Competitions WHERE id = ?", id)
    slim(:"/competitions/show",locals:{show_comp:comp_result})
end

# Checks if user is admin otherwise redirects to '/error' and displays a specified error messege
#
before('/competitions/end_season') do
    if session[:role] != 2 
        session[:error_messege] = "Du har inte behörighet för att göra detta"
        redirect('/error')
    end
end

# Ends the season which deletes all competitions and related enteties. It also adds the the win and loss count of every user into their t_wins and t_losses columns. 1 is added to titles for the owner and the horse that has the highest and then redirects to '/'
#
# @see Model#connect_db
post('/competitions/end_season') do 
    db = connect_db("db/horse_data.db")
    standing_horses = session[:s_horses]
    standing_owners = session[:s_owners]
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

    redirect("/")
end

# Displays the standings page
#
# @see Model#connect_db
get('/standings') do
    db = connect_db("db/horse_data.db")
    standing_horses = db.execute("SELECT * FROM v_StandingsHorses")
    standing_owners = db.execute("SELECT * FROM v_StandingsOwners")
    session[:s_horses] = standing_owners
    slim(:"standings", locals:{h_stand:standing_horses, o_stand:standing_owners})
end

# Displays the user page for a logged in user with a specified id, The user table and the users horses is displayed
#
# @see Model#connect_db
get('/profile') do
    user_id = session[:user_id]
    db = connect_db("db/horse_data.db")
    horse_info = db.execute("SELECT * FROM Horses WHERE owner_id = ?", user_id)
    user_result = db.execute("SELECT * FROM User WHERE id = ?", user_id)
    season_result = db.execute("SELECT (count(win)-sum(win)) AS t_losses ,sum(points) AS t_points, sum(win) AS t_wins FROM HCR inner join Horses on Horses.id = HCR.horse_id WHERE Horses.owner_id = ?", user_id)
    rank = db.execute("SELECT norank FROM v_StandingsOwners WHERE username = ?", session[:username]) 
    n_horses = db.execute("SELECT COUNT(id) AS n_horses FROM Horses WHERE owner_id = ?", user_id)
    user_result = user_result.first.merge(n_horses.first)

    if user_result["n_horses"] != 0 && user_result["n_horses"] != nil && rank.first != nil

        season_result = season_result.first.merge(rank.first)
        t_wins = user_result["t_wins"] + season_result["t_wins"]
        t_losses = user_result["t_losses"] + season_result["t_losses"]
        horse_results = db.execute("SELECT id, Horses.name, weight, height, titles, wins, losses, points, norank FROM Horses INNER JOIN v_StandingsHorses on v_StandingsHorses.name = Horses.name WHERE Horses.owner_id = ?", user_id)
        i = user_result["n_horses"]-1
        j = horse_results.length-1
        j_saved = j
        h_ids = [nil,nil,nil,nil]
        while i >= 0
            h_ids[i] = horse_info[i]["id"]
            i -= 1
        end
        i = user_result["n_horses"]-1
        while i >= 0
            while j >= 0
                if  horse_info[i]["id"] == horse_results[j]["id"]
                    horse_exists = true
                end
                j -= 1
            end
            if horse_exists == true
                horse_exists = false
            else
                rookie_horse = {
                    "id" => horse_info[i]["id"],
                    "name" => horse_info[i]["name"],
                    "weight" => horse_info[i]["weight"],
                    "height" => horse_info[i]["height"],
                    "titles" => 0,
                    "wins" => 0,
                    "losses" => 0,
                    "points" => 0,
                    "norank" => 0
                }
                horse_results << rookie_horse
            end
            i -= 1
            j = j_saved
        end 
        session[:n_horses] = user_result["n_horses"]
        session[:ranking] = season_result["norank"]
        slim(:"profile", locals:{season_r:season_result, horse_result:horse_results, user_result:user_result, twins:t_wins, tlosses:t_losses})
    else
        season_result = {
            "t_losses" => 0,
            "t_wins" => 0,
            "t_points" => 0,
            "norank" => 0
        }
        horse_results = []
        i = 0 
        while i < user_result["n_horses"]
            rookie_horse = {
                "id" => horse_info[i]["id"],
                "name" => horse_info[i]["name"],
                "weight" => horse_info[i]["weight"],
                "height" => horse_info[i]["height"],
                "titles" => 0,
                "wins" => 0,
                "losses" => 0,
                "points" => 0,
                "norank" => 0
            }
            i += 1
            horse_results << rookie_horse
        end
        t_wins = 0
        t_losses = 0
        session[:ranking] = season_result["norank"]
        session[:n_horses] = 0
        slim(:"profile", locals:{season_r:season_result, horse_result:horse_results, user_result:user_result, twins:t_wins, tlosses:t_losses})
    end
end

# Displays the register form
#
get('/register') do
    slim(:"register")
end

# Displays the register confirm page where a confirmation messege is displayed
#
get('/register_confirm') do
    slim(:"register_confirm")
end

before('/user') do
    if params[:username].empty? || params[:password].empty? || params[:password_confirm].empty?
        session[:error_messege] = "Tomma fält i formuläret"
        redirect('/error')
    end
end

# Creates a new user and redirects to '/register_confirm'
#
# @param [String] username, The username
# @param [String] password, The password
# @param [String] password, The password_confirmation
#
# @see Model#connect_db
post('/user') do 
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    role = 1
    titles = 0
    t_wins = 0
    t_losses = 0

    db = connect_db("db/horse_data.db")
    check_result = db.execute("SELECT id FROM User WHERE username = ?", username)

    if check_result.empty?
        if password == password_confirm
            password_digest = BCrypt::Password.create(password)
            check_result = db.execute("INSERT INTO User (username, password, role, t_wins, t_losses, titles) VALUES (?,?,?,?,?,?)", username, password_digest, role, t_wins, t_losses, titles)
            session[:error_messege] = username
            redirect('/register_confirm')
        else
        session[:error_messege] = "Lösenorden matchar inte"
        redirect("/error")
        end
    else
    session[:error_messege] = "Användarnamnet finns redan"
    redirect("/error")
    end
end

# Shows all horses from the horses table
#
# @see Model#connect_db
# @see Model#horses_f
get('/horses/') do
    db = connect_db("db/horse_data.db")
    horse_result = horses_f
    slim(:"/horses/index",locals:{horse_r:horse_result})
end

# Shows a horse with a specified id
#
# @param [Integer] id, The id of the horse
#
# @see Model#connect_db
get('/horses/:id') do
    db = connect_db("db/horse_data.db")
    id = params[:id].to_i
    p id
    horse_result = db.execute("SELECT * FROM Horses WHERE id = ?", id)
    p horse_result
    slim(:"/horses/show",locals:{show_horse:horse_result})
end

# Displays the form for adding a new horse
#
get('/horses/new') do
    slim(:"/horses/new")
end

# Checks if user is logged in otherwise redirects to '/error' and displays a specified error messege
#
# @param [Integer] user_id, The id of the logged in user
before('/horses') do
    if session[:user_id] == nil
        session[:error_messege] = "Du är inte inloggad"
        redirect('/error')
    end
    if params[:name_horse].empty? || params[:weight_horse].empty? || params[:height_horse].empty?
        session[:error_messege] = "Tomma fält i formuläret"
        redirect('/error')
    end
end

# Creates a new horse and redirects to '/user'
#
# @param [String] name_horse, The name of the horse
# @param [Integer] weight_horse, The weight of the horse
# @param [Integer] height_horse, The height of the horse
post('/horses') do
    owner_id = session[:user_id]
    name = params[:name_horse]
    weight = params[:weight_horse]
    height = params[:height_horse]
    titles = 0
    db = SQLite3::Database.new("db/horse_data.db")
    db.results_as_hash = false
    db.execute("INSERT INTO Horses (name, weight, height, titles, owner_id) VALUES (?,?,?,?,?)", name, weight, height, titles, owner_id)
    redirect('/')
end

# Checks if user is the owner of the horse otherwise redirects to '/error' and displays a specified error messege
#
# @param [Integer] id, The id of the horse
#
# @see Model#connect_db
before('/horses/:id/delete') do
    db = connect_db("db/horse_data.db")
    horse_owner = db.execute("SELECT owner_id FROM Horses WHERE id = ?", params[:id])
    if session[:user_id] != horse_owner.first["owner_id"]
        session[:error_messege] = "Du äger inte denna hästen"
        redirect('/error')
    end
end

# Deletes a specified horse and then redirects to '/profile'
#
# @param [Integer] id, The id of the horse
#
# @see Model#connect_db
post('/horses/:id/delete') do
    id = params[:id].to_i
    db = connect_db("db/horse_data.db")
    db.execute("DELETE FROM Horses WHERE id = ?", id)
    redirect('/profile')
end

# Checks if user is the owner of the horse otherwise redirects to '/error' and displays a specified error messege
#
# @param [Integer] id, The id of the horse
#
# @see Model#connect_db
before('/horses/:id/edit') do
    db = connect_db("db/horse_data.db")
    horse_owner = db.execute("SELECT owner_id FROM Horses WHERE id = ?", params[:id])
    if session[:user_id] != horse_owner.first["owner_id"]
        session[:error_messege] = "Du äger inte denna hästen"
        redirect('/error')
    end
end

# Displays the edit form for a specified horse
#
# @param [Integer] id, The id of the horse
#
# @see Model#connect_db
get('/horses/:id/edit') do
    id = params[:id].to_i
    db = connect_db("db/horse_data.db")
    h_result = db.execute("SELECT * FROM Horses WHERE id = ?", id)
    slim(:"/horses/edit",locals:{horse:h_result})
end

# Checks if user is the owner of the horse otherwise redirects to '/error' and displays a specified error messege
#
# @param [Integer] id, The id of the horse
#
# @see Model#connect_db
before('/horses/:id/update') do
    db = connect_db("db/horse_data.db")
    horse_owner = db.execute("SELECT owner_id FROM Horses WHERE id = ?", params[:id])
    if session[:user_id] != horse_owner.first["owner_id"]
        session[:error_messege] = "Du äger inte denna hästen"
        redirect('/error')
    end
    if params[:name_horse].empty? || params[:weight_horse].empty? || params[:height_horse].empty?
        session[:error_messege] = "Tomma fält i formuläret"
        redirect('/error')
    end
end

# Updates a specified horse and then redirects to '/profile'
#
# @param [Integer] id, The id of the horse
# @param [String] name_horse, The name of the horse
# @param [Integer] weight_horse, The weight of the horse
# @param [Integer] height_horse, The height of the horse
#
# @see Model#connect_db
post('/horses/:id/update') do
    id = params[:id]
    name = params[:name_horse]
    weight = params[:weight_horse]
    height = params[:height_horse]
    db = connect_db("db/horse_data.db")
    db.execute("UPDATE Horses SET name=?,weight=?,height=? WHERE id = ?", name, weight, height, id)
    redirect('/profile')
end

# Attempts to login and if succesful updates the correlating sessions and redirects to '/user'. If not succefull it redirects and displays a specified error messege. If user is unsucceful 3 times within 30 seconds a cooldown of 30 seconds is activated and a corresponding error messege is displayed if the user tries to log in again.
#
# @param [String] username, The username
# @param [String] password, The password
#
# @see Model#password_cooldown_detection
# @see Model#password_cooldown_counter
# @see Model#connect_db
post('/log_in') do 
    db = connect_db("db/horse_data.db")
    username = params[:username]
    password = params[:password]
    if session[:cooldown_check] == nil
        session[:timearray] = []
        session[:cooldown] = false
        session[:cooldown_check] = true
    end
    if params[:username].empty? || params[:password].empty?
        session[:error_messege] = "tomma fält i formuläret"
        redirect("/error")
    end
    result = db.execute("SELECT id, password FROM User WHERE username = ?", username)
    if session[:cooldown] == false
        if session[:timearray].length > 4
            session[:timearray].delete_at[0]
        end
        if password_cooldown_detection(session[:timearray]) != false
            session[:time] = password_cooldown_detection(session[:timearray])
            session[:cooldown] = true
        end
    end
    if session[:cooldown] == true
        if password_cooldown_counter(session[:time])
            session[:cooldown] = false
            session[:timearray] = []
        end
    end
    if session[:cooldown] == true
        session[:error_messege] = "Du har försökt för många gånger (Försök igen om 30 sekunder)"
        redirect("/error")
    end
    if result.empty?
        session[:timearray] << Time.now.to_i
        session[:time] = password_cooldown_detection(session[:timearray])
        session[:error_messege] = "användaren exsisterar inte"
        redirect("/error")
    end
    user_id = result.first["id"]
    password_digest = result.first["password"]
    BCrypt::Password.new(password_digest) == password

    if BCrypt::Password.new(password_digest) == password
        session[:user_id] = user_id
        session[:role] = db.execute("SELECT role FROM User WHERE id = ?", user_id).first["role"]
        session[:username] = username
        redirect("/profile")
    else
        session[:timearray] << Time.now.to_i
        session[:time] = password_cooldown_detection(session[:timearray])
        session[:error_messege] = "fel lösenord"
        redirect("/error")
    end
end

# Displays an error page with a previosly specified error messege
#
get('/error') do
    slim(:"error")
end

# Checks if user is logged in (has role of owner or admin) otherwise redirects to '/error' and displays a specified error messege
#
before('/log_out') do
    if session[:role] != 1 && session[:role] != 2
        session[:error_messege] = "Du kan inte logga ut om du inte är inloggad"
        redirect('/error')
    end
end

# Deletes all sessions and redirects to ('/')
#
post('/log_out') do
    session.destroy
    redirect("/")
end




