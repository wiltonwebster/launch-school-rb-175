require "sinatra"
require "sinatra/reloader"
require "tilt"
require "erubis"

get "/" do
  @list = Dir.glob("public/*").map { |file| File.basename(file)}.sort
  @list.reverse! if params[:sort] == "desc"
  
  erb :list  
end