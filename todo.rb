require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do
  erb :new_list, layout: :layout
end

def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List name must be between 1 and 100 characters"
  elsif session[:lists].any? { |list| list[:name] == name }
    "List name must be unique"
  end
end

def error_for_todo_name(name)
  if !(1..100).cover? name.size
    "Todo must be between 1 and 100 characters"
  end
end

def next_todo_id(todos)
  max = todos.map { |todo| todo[:id] }.max || 0
  max + 1
end

# Add a new todo list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created"
    redirect "/lists"
  end
end

# View single list
get "/lists/:list_id" do
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]
  erb :list, layout: :layout
end

# Edit existing todo list
get "/lists/:list_id/edit" do
  list_id = params[:list_id].to_i
  @list = session[:lists][list_id]
  erb :edit_list, layout: :layout
end

# Update existing todo list
post "/lists/:list_id" do
  list_name = params[:list_name].strip
  list_id = params[:list_id].to_i
  @list = session[:lists][id]

  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{list_id}"
  end
end

# Delete existing todo list
post "/lists/:list_id/destroy" do
  list_id = params[:list_id].to_i
  session[:lists].delete_at(list_id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# Add a new todo to a list
post "/lists/:list_id/todos" do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]
  text = params[:todo].strip

  error = error_for_todo_name(text)
  if error
    session[:error] = error
  else
    id = next_todo_id(list[:todos])
    list[:todos] << { id: id, name: text, completed: false }
    session[:success] = "The todo was added."
  end
  redirect "/lists/#{list_id}"
end

# Delete existing todo
post "/lists/:list_id/todos/:todo_id/destroy" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = session[:lists][list_id]
  todo_index = list[:todos].find_index { |todo| todo[:id] == todo_id }
  
  list[:todos].delete_at(todo_index)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{list_id}"
end

# Toggle todo completed
post "/lists/:list_id/todos/:todo_id/check" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = session[:lists][list_id]
  todo = list[:todos].select { |todo| todo[:id] == todo_id }.first
  todo[:completed] = !todo[:completed]

  session[:success] = "Todo Updated."
  redirect "/lists/#{list_id}"
end

# Complete all todos
post "/lists/:list_id/complete" do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]

  list[:todos].each { |todo| todo[:completed] = true }

  session[:success] = "Todos Complete!"
  redirect "/lists/#{list_id}"
end
