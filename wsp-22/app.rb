require 'sinatra'
require 'slim'
require 'sqlite3'

enable :sessions


get('/') do
    db = SQLite3::Database.new("db/horse_data.db")
    db.results_as_hash = true
    r_competitions = db.execute("SELECT * FROM Competitions")
    h_names = db.execute("SELECT name FROM Horses")
    
    v_standingHorses = db.execute("SELECT * FROM v_StandingsHorses")
    v_standingOwners = db.execute("SELECT * FROM v_StandingsOwners")
    p v_standingOwners
    p v_standingHorses
    p h_names
    slim(:start, locals:{competitions:r_competitions, horse_names:h_names, standing_horses:v_standingHorses, standing_owners:v_standingOwners})
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

# post('/horse-competitions-relation/:id/new') do

# end


post('/competitions/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/horse_data.db")
    db.execute("DELETE FROM Competitions WHERE id = ?", id)
    redirect('/')
end

get('/competitions/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/horse_data.db")
    db.results_as_hash = true
    e_result = db.execute("SELECT * FROM Competitions WHERE id = ?", id)
    p e_result
    p e_result[0]["id"]
    h_names = db.execute("SELECT name FROM Horses")
    slim(:"/competitions/edit",locals:{edit_comp:e_result, horse_names:h_names})
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
    db = SQLite3::Database.new("db/horse_data.db")
    db.execute("UPDATE competitions SET name=?,date=?,winner=?,p2=?,p3=?,p4=?,p5=?,p6=?,p7=?,p8=? WHERE id = ?", place, date, winner, select_2nd, select_3rd, select_4th, select_5th, select_6th, select_7th, select_8th, id)
    redirect('/')
end

get('/standings') do
    slim(:"standings/standings")
end

