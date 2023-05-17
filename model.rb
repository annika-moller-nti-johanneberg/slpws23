require 'sqlite3'
require 'bcrypt'

# Open database
#
# @return [SQLite3::Database] database
def db
    database = SQLite3::Database.new("db/store.db")
    database.results_as_hash = true
    return database
end

# Password requirements 
#
# @param [String] password, The password
# @return [nil] if everything is true
# @return [String], error message
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

# Digests password
#
# @param [String] password, The password
def digest_password(password)
    BCrypt::Password.create(password)
end

# Stores username, digested password and permission level in database
#
# @param [String] username, The users username
# @param [String] password_digest, The digested password
def store_user_data(username, password_digest)
    db.execute("INSERT INTO Users (username, password, permission_level) VALUES (?,?,?)", username, password_digest, 1)
end

# Login
#
# @param [String] username, The users username
# @param [String] password, The users password
def login(username, password)
    result = db.execute("SELECT * FROM Users WHERE username = ?", username).first
    if result != nil
        if BCrypt::Password.new(result["password"]) == password
            return result["id"]
        end
    end
    return nil
end

# Generates id for article
#
# @param [String] title, The articles title
# @return [String] id, The new article id
def generate_article_id(title)
    i = ""
    id = title.tr(" ", "_").downcase.tr("å", "a").tr("ä", "a").tr("ö", "o")

    while true
        if db.execute("SELECT * FROM Articles WHERE title = ?", id+i.to_s).length == 0
            return id+i.to_s
        else
            i = i.to_i+1
        end
    end
end

# Selects article by search
#
# @param [String] query, The search
def get_articles_by_title(query)
    db.execute("SELECT * FROM Articles WHERE title LIKE '#{query}%'")
end

# Gets an article by its id
#
# @param [String] id, The id of the article
def get_article_by_id(id)
    db.execute("SELECT * FROM Articles WHERE id = ?", id).first
end

# Stores new article in database
#
# @param [String] title, The article title
# @param [String] body, The article body
# @param [String] id, The article id
def create_article(title, body, id, user_id)
    db.execute("INSERT INTO Articles (title, body, id, user_id, protection_level) VALUES (?,?,?,?,?)", title, body, id, user_id, 1)
end

# Gets id of user who wrote article
#
# @param [String] id, The id of the article
def get_user_by_article(id)
    db.execute("SELECT user_id FROM Articles WHERE id =?", id)
end

# Deletes article from database
#
# @param [String] id, The article id
def delete_article_by_id(id)
    db.execute("DELETE FROM Articles WHERE id =?", id)
end

# Edits article
#
# @param [String] title, The article title
# @param [String] body, The article body
# @param [String] id, The article id
def edit_article_by_id(title, body, id)
    db.execute("UPDATE Articles SET title=?, body=? WHERE id=?", title, body, id)
end

# Gets users permission level
#
# @param [Integer] id, The user id
def get_permission_level_by_id(id)
    db.execute("SELECT permission_level FROM Users WHERE id=?", id).first["permission_level"]
end

# Gets an articles protection level
#
# @param [String] id, The article id 
def get_protection_level_by_id(id)
    db.execute("SELECT protection_level FROM Articles WHERE id=?", id).first["protection_level"]
end

# Store like in database
#
# @param [Integer] user_id, The users id
# @param [String] article_id, The article id
def create_like(user_id, article_id)
    db.execute("INSERT INTO Likes (user_id, article_id) VALUES (?,?)", user_id, article_id)
end

# Get like
#
# @param [Integer] user_id, The users id
# @param [String] article_id, The article id
def get_like(user_id, article_id)
    db.execute("SELECT id FROM Likes WHERE user_id=? AND article_id=?", user_id, article_id).first
end

# Gets like count
#
# @param [String] article-id, The id of the article
# @return [Integer] like_count, The amount of likes for a certain article
def get_like_count_by_article_id(article_id)
    db.execute("SELECT COUNT(*) as likes FROM Likes WHERE article_id=?", article_id).first["likes"]
end

def get_all_users()
    db.execute("SELECT id, username, permission_level FROM Users")
end

def get_user_by_id(user_id)
    db.execute("SELECT username, permission_level FROM Users WHERE id=?", user_id).first
end

def new_permission_level(permission_level, user_id)
    db.execute("UPDATE Users SET permission_level=? WHERE id=?", permission_level, user_id)
end

def get_users_by_permission_level(user_id)
    db.execute("SELECT username, id FROM Users WHERE ? > permission_level", get_permission_level_by_id(user_id))
end