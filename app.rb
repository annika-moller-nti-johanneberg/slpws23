require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require "sinatra/reloader"
require_relative 'model.rb'
enable :sessions

get('/') do
    slim(:start)
end

get('/login') do
    slim(:login)
end

post('/login') do
    username = params[:name]
    password = params[:password]
    login(username, password)
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
            password_digest = digest_password(password)
            begin #begins code to catch errors
                store_username_password_in_users(username, password_digest)
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
    @result = get_article_by_title(query)
    if @result.length == 1
        redirect("/article/id/#{@result[0]['id']}")
    end
    slim(:list_articles)
end

get('/article/id/:id') do
    id = params[:id]
    @result = get_article_by_id(id)
    slim(:article)
end

get('/article/create') do
    slim(:create_article)
end

post('/article/create') do
    title = params[:title]
    body = params[:body]
    id = create_article_id(title)
    create_article(title, body, id)
    redirect("/article/id/#{id}")
end

post('/article/id/:id/delete') do
    id = params[:id]
    delete_article_by_id(id)
    redirect("/article")
end

get('/article/id/:id/edit') do
    @id = params[:id]
    @result= get_article_by_id(@id)
    slim(:edit)
end

post('/article/id/:id/edit') do
    title = params[:title]
    body = params[:body]
    @id = params[:id]
    edit_article_by_id(title, body, @id)
    redirect("/article/id/#{@id}")
end