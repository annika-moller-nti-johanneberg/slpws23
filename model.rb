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

def store_username_password_in_users(username, password_digest)
    db.execute("INSERT INTO Users (username, password) VALUES (?,?)", username, password_digest)
end

def create_article_id(title)
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

def login(username, password)
    result = db.execute("SELECT * FROM Users WHERE username = ?", username).first
    if result != nil
        if BCrypt::Password.new(result["password"]) == password
            session["name"] = username
            redirect('/secret')
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
    db.execute("INSERT INTO Articles (title, body, id) VALUES (?,?,?)", title, body, id)
end

def delete_article_by_id(id)
    db.execute("DELETE FROM Articles WHERE id =?", id)
end

def edit_article_by_id(title, body, id)
    db.execute("UPDATE Articles SET title=?, body=? WHERE id=?", title, body, id)
end