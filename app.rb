require "sinatra"
require "slim"
require "sqlite3"
require "bcrypt"
require "sinatra/reloader"
require_relative "model.rb"
require_relative "user.rb"
enable :sessions
also_reload("model.rb")
also_reload("user.rb")

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

# Displays the root page
get("/") do
  slim(:index)
end

# Gets article
#
# @param [String] query, The search result
get("/article") do
  query = params["query"]
  @result = get_articles_by_title(query)
  if @result.length == 1
    redirect("/article/#{@result[0]["id"]}")
  end
  slim(:'/article/articles')
end

# Displays "create article"-page
get("/article/new") do
  slim(:'/article/new')
end

# Create article
#
# @param [String] title, The title of the article
# @param [String] body, The body of the article
post("/article") do
  title = params[:title]
  body = params[:body]
  id = generate_article_id(title)
  authorize(1)
  create_article(title, body, id)
  redirect("/article/#{id}")
end

# Delete article
#
# @param [String] :id, The id of the article
post("/article/:id/delete") do
  article_id = params[:id]
  authorize(get_protection_level_by_id(article_id))
  delete_article_by_id(article_id)
  redirect("/article")
end

# Displays edit-page
#
# @params [String] :id, The article id
get("/article/:id/edit") do
  @id = params[:id]
  @result = get_article_by_id(@id)
  slim(:'/article/edit')
end

# Edit article
#
# @param [String] :id, The id of the article
# @param [String] title, The title of the article
# @param [String] body, The body of the article
post("/article/:id/update") do
  title = params[:title]
  body = params[:body]
  @id = params[:id]
  authorize(get_protection_level_by_id(@id))
  edit_article_by_id(title, body, @id)
  redirect("/article/#{@id}")
end

# Create like
# 
# @param [String] :id, The id of the article
post("/article/:id/like") do
  article_id = params["id"]
  like(article_id)
  redirect("/article/#{article_id}")
end

# View article by id
#
# @param [String] :id, The id of the article
get("/article/:id") do
  id = params[:id]
  @result = get_article_by_id(id)
  @likes = get_like_count_by_article_id(id)
  slim(:'/article/article')
end