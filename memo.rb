require "sinatra"
require "sinatra/reloader"
require "pg"
require "commonmarker"

class Memo
  attr_accessor :memos
  def memos
    connection = PG.connect(host: "localhost", user: "postgres", dbname: "memoapp")
    id = connection.exec("SELECT id FROM memo")
    content = connection.exec("SELECT content FROM memo")
  end

  def save_memos
    File.open("memo.json", "w") do |file|
      JSON.dump(@memos, file)
    end
  end

  def next_id
    if memos["memos"].empty?
      return 1
    end
    memos["memos"][-1]["id"] +1
  end

  def get_content_by_id(id)
    content = nil
    memos["memos"].each do |memo|
      if id == memo["id"].to_s
        content = memo["content"]
      end
    end
    content
  end

  def update_content_by_id(id, content)
    @memos = memos
    @memos["memos"].each do |memo|
      if id == memo["id"].to_s
        memo["content"] = content
      end
    end
 end

  def delete_by_id(id)
    @memos = memos
    @memos["memos"].delete_if { |memo| id == memo["id"].to_s }
  end
end

memo = Memo.new

get "/" do
  connection = PG.connect(host: "localhost", user: "postgres", dbname: "memoapp")
  @memos = connection.exec("SELECT * FROM memo")

  erb :list
end

get "/memo/new" do
  erb :form
end

post "/memo" do
  connection = PG.connect(host: "localhost", user: "postgres", dbname: "memoapp")
  res = connection.exec("insert into memo (content) values ('#{params[:content]}') RETURNING id")
  redirect to("/memo/#{res.first['id']}")
end

get "/memo/edit/:id" do |id|
  connection = PG.connect(host: "localhost", user: "postgres", dbname: "memoapp")
  @id = id
  res = connection.exec("SELECT content FROM memo WHERE id = #{@id}")
  @content = res.first["content"]

  erb :edit_form
end

get "/memo/:id" do |id|
  connection = PG.connect(host: "localhost", user: "postgres", dbname: "memoapp")
  @id = id
  res = connection.exec("SELECT content FROM memo WHERE id = #{@id}")
  @html = CommonMarker.render_html(res.first["content"], :DEFAULT)

  erb :detail
end

patch "/memo/:id" do |id|
  content = params[:content]
  connection = PG.connect(host: "localhost", user: "postgres", dbname: "memoapp")
  @id = id
  res = connection.exec("UPDATE memo SET content = '#{params[:content]}' WHERE id = #{@id}")
  redirect to("/memo/#{@id}")
end

delete "/memo/:id" do |id|
  connection = PG.connect(host: "localhost", user: "postgres", dbname: "memoapp")
  @id = id
  connection.exec("DELETE FROM memo WHERE id = #{@id}")
  redirect to("/")
end
