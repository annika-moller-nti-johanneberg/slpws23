require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require "sinatra/reloader"

enable :sessions

def db
    database = SQLite3::Database.new("db/store.db")
    database.results_as_hash = true
    return database
end

def check_password(password)
    if password.length <= 5
        return "Password must be 6 or more characters!"
    end
    if password !~ /[A-Z]/
        return "Password needs to contain at least one uppercase letter!"
    end
    if password !~ /[!.\-_@$*?&]/
        return "Password must contain at least one special character"
    end
    return nil
end

def create_article_id(title)
    i = ""
    id = title.tr(" ", "_").downcase

    while true
        if db.execute("SELECT * FROM Articles WHERE title = ?", id+i.to_s).length == 0
            return id+i.to_s
        else
            i = i.to_i+1
        end
    end
end

get('/') do
    slim(:start)
end

get('/login') do
    slim(:login)
end

post('/login') do
    username = params[:name]
    password = params[:password]
    result = db.execute("SELECT * FROM Users WHERE username = ?", username).first
    if result != nil
        if BCrypt::Password.new(result["password"]) == password
            session["name"] = username
            redirect('/secret')
        end
    end
    session["error"] = "Username or password does not match"
    redirect('/login')
end

get('/register') do
    slim(:register)
end

post('/register') do
    session["error"] = nil
    username = params[:name]
    password = params[:password]
    password_confirmation = params[:password_confirmation]
    if password == password_confirmation
        session["error"] = check_password(password)
        if session["error"] == nil
            password_digest = BCrypt::Password.create(password)
            begin #begins code to catch errors
                db.execute("INSERT INTO Users (username, password) VALUES (?,?)", username, password_digest)
            rescue SQLite3::ConstraintException => error #catches constraint exceptions
                if error.message.include?("name") #checks if constraint exception is of type name
                    session["error"] = "Username already exists"
                    redirect('/register')
                end
            end
        else
            redirect('/register')
        end
    else 
        session["error"] = "Passwords does not match!"
        redirect('/register')
    end
    redirect('/')
end

get('/secret') do
    if session["name"] == nil
      redirect('/login')
    end
    return "hemligt"
end

get('/article') do
    query = params["query"]
    @result = db.execute("SELECT * FROM Articles WHERE title LIKE '#{query}%'")
    if @result.length == 1
        redirect("/article/#{@result[0]['id']}")
    end
    slim(:list_articles)
end

get('/article/:id') do
    id = params[:id]
    @result = db.execute("SELECT * FROM Articles WHERE id = ?", id).first
    slim(:article)
end

get('/article/create') do
    slim(:create_article)
end

post('/article/create') do
    title = params[:title]
    body = params[:body]
    id = create_article_id(title)
    db.execute("INSERT INTO Articles (title, body, id) VALUES (?,?,?)", title, body, id)
    redirect("/article/#{id}")
end