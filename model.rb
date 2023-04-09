require 'sqlite3'
require 'bcrypt'

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

def digest_password(password)
    BCrypt::Password.create(password)
end

def store_user_data(username, password_digest)
    db.execute("INSERT INTO Users (username, password, permission_level) VALUES (?,?,?)", username, password_digest, 1)
end

def login(username, password)
    result = db.execute("SELECT * FROM Users WHERE username = ?", username).first
    if result != nil
        if BCrypt::Password.new(result["password"]) == password
            session["name"] = username
            session["id"] = result["id"]
            session["error"] = nil
            redirect('/article')
        end
    end
end

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

def get_article_by_title(query)
    db.execute("SELECT * FROM Articles WHERE title LIKE '#{query}%'")
end

def get_article_by_id(id)
    db.execute("SELECT * FROM Articles WHERE id = ?", id).first
end

def create_article(title, body, id)
    db.execute("INSERT INTO Articles (title, body, id, protection_level) VALUES (?,?,?,?)", title, body, id, 1)
end

def delete_article_by_id(id)
    db.execute("DELETE FROM Articles WHERE id =?", id)
end

def edit_article_by_id(title, body, id)
    db.execute("UPDATE Articles SET title=?, body=? WHERE id=?", title, body, id)
end

def get_permission_level_by_id(id)
    db.execute("SELECT permission_level FROM Users WHERE id=?", id).first
end

def get_protection_level_by_id(id)
    db.execute("SELECT protection_level FROM Articles WHERE id=?", id).first
end

def create_like(user_id, article_id)
    db.execute("INSERT INTO Likes (user_id, article_id) VALUES (?,?)", user_id, article_id)
end

def get_like(user_id, article_id)
    db.execute("SELECT id FROM Likes WHERE user_id=? AND article_id=?", user_id, article_id).first
end

def get_likes_by_article_id(article_id)
    db.execute("SELECT COUNT(*) as likes FROM Likes WHERE article_id=?", article_id).first["likes"]
end