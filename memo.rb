require "sinatra"
require "sinatra/reloader"
require "json"
require "commonmarker"

class Memo
  attr_accessor :memos
  def memos
    File.open("memo.json", "r") do |file|
        @memos = JSON.load(file)
      end
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
  @memos = memo.memos["memos"]
  erb :list
end

get "/memo/new" do
  erb :form
end

post "/memo" do
  @content = params[:content]
  @id = memo.next_id
  memo.memos["memos"].push({ id: @id, content: @content })
  memo.save_memos
  redirect to("/memo/#{@id}")
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
  content = params[:content]
  memo.update_content_by_id(id, content)
  memo.save_memos
  redirect to("/memo/#{id}")
end

delete "/memo/:id" do |id|
  memo.delete_by_id(id)
  memo.save_memos
  redirect to("/")
end
