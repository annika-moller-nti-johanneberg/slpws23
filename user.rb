require 'sqlite3'
require 'bcrypt'

# Displays the login-page
get("/login") do
    slim(:'/user/login')
  end
  
  last_login = Hash.new(0)
  
  # Login
  #
  # @param [String] username, The users username
  # @param [String] password, The users password
  post("/login") do
    if Time.now.to_f - last_login[request.ip] < 1
      session["error"] = "Too many tries, wait a sec"
      redirect("/login")
    end
    username = params[:name]
    password = params[:password]
    login(username, password)
    session["error"] = "Username or password does not match"
    last_login[request.ip] = Time.now.to_f
    redirect("/login")
  end
  
  # Displays the register-page
  get("/register") do
    slim(:'/user/register')
  end
  
  # Register new user
  #
  # @param [String] name, The username of the user
  # @param [String] password, The password of the user
  # @param [String] password_confirmation, The password of the user again
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
  end
  
  # Logout the user
  get("/logout") do
    session.clear
    redirect("/")
  end