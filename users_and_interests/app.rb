require "sinatra"
require "sinatra/reloader"
require "tilt"
require "erubis"
require "yaml"

before do
  @user_list = YAML.load_file("users.yaml")
end

get "/" do
  redirect "/users"
end

get "/users" do
  erb :user_list
end

get "/users/:user" do
  @name = params[:user]
  
  @email = @user_list[@name.to_sym][:email]
  @interest_list = @user_list[@name.to_sym][:interests].map(&:capitalize).join(", ")
  @other_users = @user_list.reject { |name, _| name == @name.to_sym }
  
  erb :user_profile
end

helpers do
  def count_interests
    @user_list.values.map { |attributes| attributes[:interests].size }.inject(:+)
  end
end