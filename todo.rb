require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
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

  unless @lists.empty?
    true_list = []
    false_list = []
    @lists.each do |list|
      if list[:todos].all? { |todo| todo[:completed] == true  }
        true_list << list
      else
        false_list << list
      end
    end
    @lists = true_list + false_list
  end

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

# Create a new list
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
get "/lists/:id" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:id/edit" do
  id = params[:id].to_i
  @list = session[:lists][id]
  erb :edit_list, layout: :layout
end

# Update an existing todo list
post "/lists/:id" do
  list_name = params[:list_name].strip
  id = params[:id].to_i
  @list = session[:lists][id]

  error = error_for_list_name(list_name)
  if error
    id = params[:id].to_i
    @list = session[:lists][id]
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    @list[:name] = list_name
    session[:success] = "The list has been updated."
    redirect "/lists/#{id}"
  end
end

# Delete an existing todo list
post "/lists/:id/destroy" do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted."
  redirect "/lists"
end

# Create a new todo
post "/lists/:list_id/todos" do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]
  todo_name = params[:todo].strip

  error = error_for_todo_name(todo_name)
  if error
    session[:error] = error
  else
    list[:todos] << { name: params[:todo], completed: false }
    session[:success] = "The todo was added."
  end
  redirect "/lists/#{list_id}"
end

# Delete an existing todo list
post "/lists/:list_id/todos/:todo_id/destroy" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = session[:lists][list_id]

  list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{list_id}"
end

post "/lists/:list_id/todos/:todo_id/check" do
  list_id = params[:list_id].to_i
  todo_id = params[:todo_id].to_i
  list = session[:lists][list_id]
  list[:todos][todo_id][:completed] = !list[:todos][todo_id][:completed]
  session[:success] = "Todo Updated."
  redirect "/lists/#{list_id}"
end

post "/lists/:list_id/complete" do
  list_id = params[:list_id].to_i
  list = session[:lists][list_id]

  list[:todos].each_with_index do | todo, index |
    todo[:completed] = true
  end

  session[:success] = "Todos Complete!"
  redirect "/lists/#{list_id}"
end
