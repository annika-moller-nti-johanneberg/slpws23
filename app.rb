require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"
require "sinatra/reloader"
require_relative "model.rb"
require_relative "user.rb"
require_relative "article.rb"
enable :sessions
also_reload("model.rb")
also_reload("user.rb")
also_reload("article.rb")

# Check permission level and redirect if not fulfilled
#
# @param [Integer] protection_level, The articles level of protection
def authorize(protection_level)
  user_id = session["id"]
  permission_level = get_permission_level_by_id(user_id)

  if user_id == nil
    session["error"] = "You need to be logged in"
    redirect("/login")
  elsif permission_level < protection_level
    session["error"] = "You do not have permission to do that"
    redirect("/article")
  end
end

# Check if user has alredy liked and redirect if not fulfilled
#
# @param [String] article_id, The article id
def like(article_id)
  user_id = session["id"]
  existing_like = get_like(user_id, article_id)
  p existing_like

  if user_id == nil
    session["error"] = "You need to be logged in"
    redirect("/login")
  elsif existing_like != nil
    session["error"] = "You have already liked this article"
    redirect('/article/'+article_id)
  else
    create_like(user_id, article_id)
    session["error"] = nil
  end
end

['/article/:id/delete', '/article/new', '/article/:id/edit', '/article/:id/like', '/users', '/user/:id', '/user/:id/update'].each do |route|
  before(route) do
    user_id = session["id"]
    if user_id == nil
      session["error"] = "You need to be logged in"
      redirect("/login")
    end
  end
end

# Displays the root page
get("/") do
  slim(:index)
end
