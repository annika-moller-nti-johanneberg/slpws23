require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"
require "sinatra/reloader"
require_relative "model.rb"
enable :sessions
also_reload("model.rb")

def authorize(protection_level)
  user_id = session["id"]
  permission_level = get_permission_level_by_id(user_id)

  if user_id == nil
    session["error"] = "You need to be logged in"
    redirect("/login")
  elsif permission_level["permission_level"] < protection_level["protection_level"]
    session["error"] = "You do not have permission to do that"
    redirect("/article")
  end
end

def like(article_id)
  user_id = session["id"]
  existing_like = get_like(user_id, article_id)
  p existing_like

  if user_id == nil
    session["error"] = "You need to be logged in"
    redirect("/login")
  elsif existing_like != nil
    session["error"] = "You have already liked this article"
    redirect('/article/id/'+article_id)
  else
    create_like(user_id, article_id)
    session["error"] = nil
  end
end

get("/") do
  slim(:start)
end

get("/login") do
  slim(:login)
end

post("/login") do
  username = params[:name]
  password = params[:password]
  login(username, password)
  session["error"] = "Username or password does not match"
  redirect("/login")
  session["error"] = nil
end

get("/register") do
  slim(:register)
end

post("/register") do
  session["error"] = nil
  username = params[:name]
  password = params[:password]
  password_confirmation = params[:password_confirmation]
  if password == password_confirmation
    session["error"] = check_password(password)
    if session["error"] == nil
      password_digest = digest_password(password)
      begin #begins code to catch errors
        store_user_data(username, password_digest)
      rescue SQLite3::ConstraintException => error #catches constraint exceptions
        if error.message.include?("name") #checks if constraint exception is of type name
          session["error"] = "Username already exists"
          redirect("/register")
        end
      end
    else
      redirect("/register")
    end
  else
    session["error"] = "Passwords does not match!"
    redirect("/register")
  end
  redirect("/")
  session["error"] = nil
end

get("/secret") do
  if session["name"] == nil
    redirect("/login")
  end
  return "hemligt"
end

get("/article") do
  query = params["query"]
  @result = get_article_by_title(query)
  if @result.length == 1
    redirect("/article/id/#{@result[0]["id"]}")
  end
  slim(:list_articles)
end

get("/article/id/:id") do
  id = params[:id]
  @result = get_article_by_id(id)
  @likes = get_likes_by_article_id(id)
  slim(:article)
end

get("/article/create") do
  slim(:create_article)
end

post("/article/create") do
  title = params[:title]
  body = params[:body]
  id = generate_article_id(title)
  create_article(title, body, id)
  redirect("/article/id/#{id}")
end

post("/article/id/:id/delete") do
  article_id = params[:id]
  authorize(get_protection_level_by_id(article_id))
  delete_article_by_id(article_id)
  redirect("/article")
end

get("/article/id/:id/edit") do
  @id = params[:id]
  @result = get_article_by_id(@id)
  slim(:edit)
end

post("/article/id/:id/edit") do
  title = params[:title]
  body = params[:body]
  @id = params[:id]
  authorize(get_protection_level_by_id(@id))
  edit_article_by_id(title, body, @id)
  redirect("/article/id/#{@id}")
end

post("/article/id/:id/like") do
  article_id = params["id"]
  like(article_id)
end
