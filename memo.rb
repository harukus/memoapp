require "sinatra"
require "sinatra/reloader"
require "pg"
require "commonmarker"

class Memo
  def initialize
    @conn = PG.connect(host: "localhost", user: "postgres", dbname: "memoapp")
    @conn.prepare("insert_memo", "insert into memo (content) values ($1)  RETURNING id")
    @conn.prepare("get_memo", "SELECT content FROM memo WHERE id = $1")
    @conn.prepare("update_memo", "UPDATE memo SET content = $1 WHERE id = $2")
    @conn.prepare("delete_memo", "DELETE FROM memo WHERE id = $1")
  end
  def list_all
    @conn.exec("SELECT * FROM memo")
  end

  def add(content)
    res = @conn.exec_prepared("insert_memo", [content])
    res.first["id"]
  end

  def get_content_by_id(id)
    res = @conn.exec_prepared("get_memo", [id])
    res.first["content"]
  end

  def update_content_by_id(id, content)
    @conn.exec_prepared("update_memo", [content, id])
 end

  def delete_by_id(id)
    @conn.exec_prepared("delete_memo", [id])
  end
end

memo = Memo.new

get "/" do
  @memos = memo.list_all

  erb :list
end

get "/memo/new" do
  erb :form
end

post "/memo" do
  id = memo.add(params[:content])
  redirect to("/memo/#{id}")
end

get "/memo/edit/:id" do |id|
  @id = id
  @content = memo.get_content_by_id(id)
  erb :edit_form
end

get "/memo/:id" do |id|
  @id = id
  content = memo.get_content_by_id(id)
  @html = CommonMarker.render_html(content, :DEFAULT)

  erb :detail
end

patch "/memo/:id" do |id|
  memo.update_content_by_id(id, params[:content])
  redirect to("/memo/#{id}")
end

delete "/memo/:id" do |id|
  memo.delete_by_id(id)
  redirect to("/")
end
