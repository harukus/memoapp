require "sinatra"
require "sinatra/reloader"
require "json"
require "commonmarker"


class Rack::MethodOverride
  ALLOWED_METHODS = %w[POST]

  def method_override(env)
    req = Rack::Request.new(env)
    method = req.params[METHOD_OVERRIDE_PARAM_KEY] || env[HTTP_METHOD_OVERRIDE_HEADER]
    method.to_s.upcase
  end
end

enable :method_override

def get_memos
  memos = nil
  File.open("memo.json", "r") do |f|
    memos = JSON.load(f)
  end
  memos
end

def post_memos(memos)
  File.open("memo.json", "w") do |file|
    JSON.dump(memos, file)
  end
end

def save_id(file)
  if file["memos"].empty?
    last_id = 0
  else
    last_id = file["memos"][-1]["id"]
  end
  next_id = last_id + 1
  @id = next_id
end

def list_memo(x, id)
  if id == x["id"].to_s
    @id = id
    @memo = x["memo"]
    p @memo_to_html = CommonMarker.render_html(@memo, :DEFAULT)
  end
end

def edit_memo(x, id)
  if id == x["id"].to_s
    x["memo"] = params[:memo]
  end
end

get "/" do
  @memos = get_memos["memos"]
  erb :list
end

get "/memo/new" do
  erb :form
end

post "/memo" do
  @memo = params[:memo]
  @memos = get_memos
  save_id(@memos)
  @memos["memos"].push({ id: @id, memo: @memo })
  post_memos(@memos)
  redirect to("/memo/#{@id}")
end

get "/memo/edit/:id" do |id|
  @memos = get_memos["memos"]
  @memos.each { |x|
    list_memo(x, id)
  }
  erb :edit_form
end

get "/memo/:id" do |id|
  @memos = get_memos["memos"]
  @memos.each { |x|
    list_memo(x, id)
  }
  erb :detail
end

patch "/memo/:id" do |id|
  @memos = get_memos
  @memos["memos"].each { |x|
    edit_memo(x, id)
  }
  post_memos(@memos)
  redirect to("/memo/#{id}")
end

delete "/memo/:id" do |id|
  @id = id
  @memos = get_memos
  @memos["memos"].delete_if { |x| id == x["id"].to_s }
  post_memos(@memos)
  redirect to("/")
end
