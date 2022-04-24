require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative 'model.rb'

enable :sessions

include Model

helpers do 

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

before do 

if (session[:role] != 1 && session[:role] != 2) && request.path_info != ('/') && request.path_info != ('/standings') && request.path_info != ('/error') && request.path_info != ('/register') && request.path_info != ('/log_in') && request.path_info != ('/user/new') && request.path_info != ('/register_confirm')
session[:error_messege] = "Du har inte behörighet till denna sidan"
redirect('/error')
end
    
end

get('/') do
    db = connect_db("db/horse_data.db")
    r_competitions = competitions_f
    if r_competitions.empty?
        p "Här inne"
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
        p comp_r[0].length
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
        p "här"
    end

    r_competitions = competitions_f
    h_names = db.execute("SELECT name FROM Horses")
    v_standingHorses = db.execute("SELECT * FROM v_StandingsHorses LIMIT 3;")
    v_standingOwners = db.execute("SELECT * FROM v_StandingsOwners")
    slim(:start, locals:{competitions:r_competitions, horse_names:h_names, standing_horses:v_standingHorses, standing_owners:v_standingOwners, user:r_user})
end

before('/competitions/new') do
    if session[:role] != 2 
        session[:error_messege] = "Du har inte behörighet för att göra detta"
        redirect('/error')
    end
    if params[:place_comp].empty? || params[:date_comp].empty?
        session[:error_messege] = "Fel input"
        redirect('/error')
    end
end

post('/competitions/new') do
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
    p comp_r
    p comp_r[0].length
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

before('/competitions/:id/delete') do
    if session[:role] != 2 
        session[:error_messege] = "Du har inte behörighet för att göra detta"
        redirect('/error')
    end
end

post('/competitions/:id/delete') do
    id = params[:id].to_i
    db = connect_db("db/horse_data.db")
    db.execute("DELETE FROM Competitions WHERE id = ?", id)
    db.execute("DELETE FROM HCR WHERE competition_id = ?", id)
    redirect('/')
end

before('/competitions/:id/edit') do
    if session[:role] != 2 
        session[:error_messege] = "Du har inte behörighet för att göra detta"
        redirect('/error')
    end
end

get('/competitions/:id/edit') do
    id = params[:id].to_i
    db = connect_db("db/horse_data.db")
    e_result = db.execute("SELECT * FROM Competitions WHERE id = ?", id)
    p e_result
    p e_result[0]["id"]
    h_names = db.execute("SELECT name FROM Horses")
    slim(:"/competitions/edit",locals:{edit_comp:e_result, horse_names:h_names})
end

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
    p comp_r
    p comp_r[0].length
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

before('/competitions/end_season') do
    if session[:role] != 2 
        session[:error_messege] = "Du har inte behörighet för att göra detta"
        redirect('/error')
    end
end

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

get('/standings') do
    db = connect_db("db/horse_data.db")
    standing_horses = db.execute("SELECT * FROM v_StandingsHorses")
    standing_owners = db.execute("SELECT * FROM v_StandingsOwners")
    session[:s_horses] = standing_owners
    slim(:"standings", locals:{h_stand:standing_horses, o_stand:standing_owners})
end

get('/user') do
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
        p t_wins = user_result["t_wins"] + season_result["t_wins"]
        p t_losses = user_result["t_losses"] + season_result["t_losses"]
        p horse_results = db.execute("SELECT id, Horses.name, weight, height, titles, wins, losses, points, norank FROM Horses INNER JOIN v_StandingsHorses on v_StandingsHorses.name = Horses.name WHERE Horses.owner_id = ?", user_id)
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
                    p "är här"
                end
                j -= 1
            end
            if horse_exists == true
                horse_exists = false
            else
                p horse_info[i]
                p i
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
        slim(:"user/index", locals:{season_r:season_result, horse_result:horse_results, user_result:user_result, twins:t_wins, tlosses:t_losses})
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
        slim(:"user/index", locals:{season_r:season_result, horse_result:horse_results, user_result:user_result, twins:t_wins, tlosses:t_losses})
    end


end

get('/register') do
    slim(:"register")
end

get('/register_confirm') do
    slim(:"register_confirm")
end

post('/user/new') do 
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
            p password_digest
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

get('/horses/new') do
    slim(:"/horses/new")
end

before('/horses/new') do
    if session[:user_id].empty?
        session[:error_messege] = "Du är inte inloggad"
        redirect('/error')
    end
    if params[:name_horse].empty? || params[:weight].empty? || params[:height_horse].empty?
        session[:error_messege] = "Fel input"
        redirect('/error')
    end
end

post('/horses/new') do
    owner_id = session[:user_id]
    name = params[:name_horse]
    weight = params[:weight_horse]
    height = params[:height_horse]
    titles = 0
    db = SQLite3::Database.new("db/horse_data.db")
    db.results_as_hash = false
    db.execute("INSERT INTO Horses (name, weight, height, titles, owner_id) VALUES (?,?,?,?,?)", name, weight, height, titles, owner_id)
    redirect('/user')
end

before('/horses/:id/delete') do
    db = connect_db("db/horse_data.db")
    horse_owner = db.execute("SELECT owner_id FROM Horses WHERE id = ?", params[:id])
    if session[:user_id] != horse_owner
        session[:error_messege] = "Du äger inte denna hästen"
        redirect('/error')
    end
end

post('/horses/:id/delete') do
    id = params[:id].to_i
    db = connect_db("db/horse_data.db")
    db.execute("DELETE FROM Horses WHERE id = ?", id)
    redirect('/user')
end

before('/horses/:id/edit') do
    db = connect_db("db/horse_data.db")
    horse_owner = db.execute("SELECT owner_id FROM Horses WHERE id = ?", params[:id])
    if session[:user_id] != horse_owner
        session[:error_messege] = "Du äger inte denna hästen"
        redirect('/error')
    end
end

get('/horses/:id/edit') do
    id = params[:id].to_i
    db = connect_db("db/horse_data.db")
    h_result = db.execute("SELECT * FROM Horses WHERE id = ?", id)
    slim(:"/horses/edit",locals:{horse:h_result})
end

before('/horses/:id/update') do
    db = connect_db("db/horse_data.db")
    horse_owner = db.execute("SELECT owner_id FROM Horses WHERE id = ?", params[:id])
    if session[:user_id] != horse_owner
        session[:error_messege] = "Du äger inte denna hästen"
        redirect('/error')
    end
end

post('/horses/:id/update') do
    id = params[:id]
    name = params[:name_horse]
    weight = params[:weight_horse]
    height = params[:height_horse]
    db = connect_db("db/horse_data.db")
    db.execute("UPDATE Horses SET name=?,weight=?,height=? WHERE id = ?", name, weight, height, id)
    redirect('/user')
end


post('/log_in') do 
    db = connect_db("db/horse_data.db")
    username = params[:username]
    password = params[:password]
    p session[:cooldown_check]
    if session[:cooldown_check] == nil
        session[:timearray] = []
        session[:cooldown] = false
        session[:cooldown_check] = true
    end
    p session[:timearray]
    result = db.execute("SELECT id, password FROM User WHERE username = ?", username)
    if session[:cooldown] == false
        if session[:timearray].length > 4
            session[:timearray].delete_at[0]
            p session[:timearray]
        end
        if password_cooldown_detection(session[:timearray]) != false
            session[:time] = password_cooldown_detection(session[:timearray])
            session[:cooldown] = true
        end
    end
    if session[:cooldown] == true
        p "Här inne"
        p password_cooldown_counter(session[:time])
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
    p user_id = result.first["id"]
    p password_digest = result.first["password"]
    p BCrypt::Password.new(password_digest) == password

    if BCrypt::Password.new(password_digest) == password
        session[:user_id] = user_id
        session[:role] = db.execute("SELECT role FROM User WHERE id = ?", user_id).first["role"]
        session[:username] = username
        redirect("/user")
    else
        session[:timearray] << Time.now.to_i
        session[:time] = password_cooldown_detection(session[:timearray])
        session[:error_messege] = "fel lösenord"
        redirect("/error")
    end
end

get('/error') do
    slim(:"error")
end

before('/log_out') do
    if session[:role] != 1 && session[:role] != 2
        session[:error_messege] = "Du kan inte logga ut om du inte är inloggad"
        redirect('/error')
    end
end

post('/log_out') do
    session.destroy
    redirect("/")
end




