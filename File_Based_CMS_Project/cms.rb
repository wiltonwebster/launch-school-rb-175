require "sinatra"
require "sinatra/reloader"
require "sinatra/content_for"
require "tilt"
require "erubis"
require "redcarpet"
require "yaml"

configure do
  enable :sessions
  set :session_secret, SecureRandom.hex(32)
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../data", __FILE__)
  end
end

def load_user_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/users.yml", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
  YAML.load_file(credentials_path)
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  end
end

def user_signed_in?
  session.key?(:username)
end

def require_signed_in_user
  unless user_signed_in?
    session[:message] = "You must be signed in to do that."
    redirect "/"
  end
end

get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map do |path|
    File.basename(path)
  end.sort
  
  erb :index
end

get "/users/signin" do
  erb :signin
end

post "/users/signin" do
  credentials = load_user_credentials
  username = params[:username]
  
  if credentials.key?(username) && credentials[username] == params[:password]
    session[:username] = username
    session[:message] = "Welcome!"
    redirect "/"
  else
    session[:message] = "Invalid credentials"
    status 422
    erb :signin
  end
end

post "/users/signout" do
  session.delete(:username)
  session[:message] = "You have been signed out."
  redirect "/"
end

get "/new" do
  require_signed_in_user
  
  erb :new
end

post "/create" do
  require_signed_in_user
  
  file_name = params[:filename].to_s
  error = error_for_file_name(file_name)
  
  if error
    session[:message] = error
    status 422
    
    erb :new
  else
    file_path = File.join(data_path, file_name)
    
    File.write(file_path, "")
    
    session[:message] = "#{file_name} has been created."
    redirect "/"
  end
end

def error_for_file_name(filename)
  "A name is required." if filename.empty?
end

get "/:filename" do
  file_name = params[:filename]
  file_path = File.join(data_path, file_name)
  
  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{file_name} does not exist."
    redirect "/"
  end
end

get "/:filename/edit" do
  require_signed_in_user
  
  @file_name = params[:filename]
  file_path = File.join(data_path, @file_name)
  
  @content = File.read(file_path)
  
  erb :edit
end

post "/:filename" do
  require_signed_in_user
  
  file_name = params[:filename]
  file_path = File.join(data_path, file_name)
  
  File.write(file_path, params[:content])
  
  session[:message] = "#{file_name} has been updated."
  redirect "/"
end

post "/:filename/destroy" do
  require_signed_in_user
  
  file_name = params[:filename]
  file_path = File.join(data_path, file_name)
  
  File.delete(file_path)
  
  session[:message] = "#{file_name} has been deleted."
  redirect "/"
end