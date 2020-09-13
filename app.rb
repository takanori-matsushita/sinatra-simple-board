
require 'sinatra'
require 'sinatra/reloader'
require 'pry'
require 'pg'
require 'sinatra/cookies'
require 'digest'

enable :sessions

# データベースへの接続設定
client = PG::connect(
  :host => "localhost",
  :user => ENV.fetch("USER", "taka"),
  :password => '',
  :dbname => "myapp"
)

# 投稿リスト
get '/' do
  @message = session.delete :message if session[:message]  # session[:message]に値が代入されている場合、セッションメッセージ@messageへ代入し、session[:message]を削除する
  @posts = client.exec_params("select  posts.id, posts.title, posts.content, posts.post_img, users.name from posts inner join users on users.id = posts.user_id").to_a
  return erb :top
end

get '/about' do
  return erb :about
end

get '/register' do
  if session[:user] # ログイン済みだった場合
    session[:message] = { key: 'warning', value: 'すでにログインしています' } # フラッシュメッセージを代入
    return redirect '/mypage' # マイページへリダイレクトする。
  end
  @message = session.delete :message if session[:message] # session[:message]に値が代入されている場合、セッションメッセージ@messageへ代入し、session[:message]を削除する
  return erb :register
end

post '/register' do
  name = params[:name]
  email = params[:email]
  password = params[:password]
  password_confirmation = params[:password_confirmation]
  if name.empty? || email.empty? || password.empty? # 名前、メールアドレス、パスワードが空白だった場合
    session[:message] = { key: 'danger', value: '必須項目は入力してください' } # フラッシュメッセージを代入
    return redirect '/register' # 登録ページへリダイレクトする
  elsif password != password_confirmation # パスワードとパスワード確認用の値が一致しない場合
    session[:message] = { key: 'danger', value: 'パスワードが一致しません' } # フラッシュメッセージを代入
    return redirect '/register' # 登録ページへリダイレクトする
  elsif password.size < 6 # パスワードが6文字未満の場合
    session[:message] = { key: 'danger', value: 'パスワードは6文字以上入力してください' } # フラッシュメッセージを代入
    return redirect '/register' # 登録ページへリダイレクトする
  end
  begin # 例外処理。
    secure_password = Digest::SHA512.hexdigest(params[:password_confirmation]) # パスワードを暗号化し、secure_passwordに代入
    user = client.exec_params("insert into users(name, email, password) values($1, $2, $3) returning *", [name, email, secure_password]).to_a.first
  rescue PG::UniqueViolation # 例外処理。以下の処理を実行した際に、PG::UniqueViolationエラーが出た場合
    session[:message] = { key: 'danger', value: 'そのメールアドレスはすでに使われています' } # フラッシュメッセージを代入
    return redirect '/register' # 登録ページへリダイレクトする
  end
  session[:user] = user # ユーザー登録と同時にログインする
  session[:message] = { key: 'success', value: 'ログインしました' } # フラッシュメッセージを代入
  return redirect '/mypage' # マイページへリダイレクトする
end

get '/login' do
  if session[:user] # ログイン済みの場合
    session[:message] = { key: 'warning', value: 'すでにログインしています' } # フラッシュメッセージを代入
    return redirect '/mypage' # マイページへリダイレクトする。
  end
  @message = session.delete :message if session[:message]  # session[:message]に値が代入されている場合、セッションメッセージ@messageへ代入し、session[:message]を削除する
  return erb :login
end

post '/login' do
  email = params[:email]
  password = Digest::SHA512.hexdigest(params[:password]) # パスワードを暗号化し、passwordに代入
  user = client.exec_params("select * from users where email = $1 and password = $2",[email, password]).to_a.first
  if user
    session[:user] = user # session[:user]にuserを代入
    session[:message] = { key: 'success', value: 'ログインしました' } # フラッシュメッセージを代入
    return redirect '/mypage' # マイページへリダイレクトする
  end
  session[:message] = { key: 'danger', value: 'メールアドレスもしくはパスワードが違います' } # フラッシュメッセージを代入
  return redirect '/login'  # ログインページへリダイレクトする# ログインページへリダイレクトする
end

get '/mypage' do
  if session[:user].nil? # ログインしていない場合 # ログインしていない場合
    session[:message] = { key: 'danger', value: 'ログインしてください' } # フラッシュメッセージを代入
    redirect '/login'  # ログインページへリダイレクトする# ログインページへリダイレクトする
  end
  @message = session.delete :message if session[:message] # session[:message]に値が代入されている場合、セッションメッセージ@messageへ代入し、session[:message]を削除する
  @posts = client.exec_params("select  posts.id, posts.title, posts.content, posts.post_img, users.name from posts inner join users on users.id = posts.user_id").to_a
  return erb :mypage
end

put '/mypage' do
  if session[:user].nil? # ログインしていない場合 # ログインしていない場合
    session[:message] = { key: 'danger', value: 'ログインしてください' } # フラッシュメッセージを代入
    redirect '/login'  # ログインページへリダイレクトする# ログインページへリダイレクトする
  end
  name = params[:name]
  email = params[:email]
  image = params[:img]
  password = params[:password]  
  password_confirmation = params[:password_confirmation]
  if name.empty? || email.empty? || password.empty? # 名前とメールアドレスとパスワードが空白の場合
    session[:message] = { key: 'danger', value: '必須項目は入力してください' } # フラッシュメッセージを代入
    return redirect '/mypage' # マイページへリダイレクトする
  elsif password != password_confirmation #パスワードとパスワード確認用の値が一致しない場合
    session[:message] = { key: 'danger', value: 'パスワードが一致しません' } # フラッシュメッセージを代入
    return redirect '/mypage' # マイページへリダイレクトする
  end
  if password.empty? && image.nil? # パスワードが空白で、画像がない場合
    session[:user] = client.exec_params("update users set name = $1, email = $2 where id = $3 returning *", [name, email, session[:user]["id"]]).to_a.first
    session[:message] = { key: 'success', value: 'ユーザー情報を更新しました' } # フラッシュメッセージを代入
    return redirect '/mypage' # マイページへリダイレクトする
  elsif password.empty? && image # パスワードが空白で画像がある場合
    tempfile = params[:img][:tempfile]
    save_to = "./public/images/#{params[:img][:filename]}"
    FileUtils.mv(tempfile, save_to)
    session[:user] = client.exec_params("update users set name = $1, email = $2, profile_img = $3 where id = $4 returning *", [name, email, params[:img][:filename], session[:user]["id"]]).to_a.first
    return redirect '/mypage' # マイページへリダイレクトする
  elsif password.size < 6 # パスワードが6文字以下の場合
    session[:message] = { key: 'danger', value: 'パスワードは6文字以上入力してください' } # フラッシュメッセージを代入
    return redirect '/mypage' # マイページへリダイレクトする
  end
  secure_password = Digest::SHA512.hexdigest(password) # パスワードを暗号化し、secure_passwordに代入
  if image # 画像がある場合
    tempfile = params[:img][:tempfile]
    save_to = "./public/images/#{params[:img][:filename]}"
    FileUtils.mv(tempfile, save_to)
    session[:user] = client.exec_params("update users set name = $1, email = $2, password = $3, post_img = $4 where id = $5 returning *", [name, email, secure_password, params[:img][:filename], session[:user]["id"]]).to_a.first
    session[:message] = { key: 'success', value: 'ユーザー情報を更新しました' } # フラッシュメッセージを代入
    return redirect '/mypage' # マイページへリダイレクトする
  else
    session[:user] = client.exec_params("update users set name = $1, email = $2, password = $3 where id = $4 returning *", [name, email, secure_password, session[:user]["id"]]).to_a.first
    session[:message] = { key: 'success', value: 'ユーザー情報を更新しました' } # フラッシュメッセージを代入
  return redirect '/mypage' # マイページへリダイレクトする
  end
end

delete '/logout' do
  if session[:user].nil? # ログインしていない場合
    session[:message] = { key: 'danger', value: 'ログインしてください' } # フラッシュメッセージを代入
    redirect '/login'  # ログインページへリダイレクトする # ログインページへリダイレクトする
  end
  session[:user] = nil
  session[:message] = { key: 'danger', value: 'ログアウトしました' } # フラッシュメッセージを代入
  redirect '/login'
end

get '/post/:id' do
  @message = session.delete :message if session[:message] # session[:message]に値が代入されている場合、セッションメッセージ@messageへ代入し、session[:message]を削除する
  @post = client.exec_params("select posts.id, posts.title, posts.content, posts.post_img, users.name from posts inner join users on users.id = posts.user_id").to_a.first
  return erb :show_post
end

get '/posts/new' do
  @message = session.delete :message if session[:message] # session[:message]に値が代入されている場合、セッションメッセージ@messageへ代入し、session[:message]を削除する
  if session[:user].nil? # ログインしていない場合
    session[:message] = { key: 'danger', value: 'ログインしてください' } # フラッシュメッセージを代入
    redirect '/login'
  end
  return erb :new_posts
end

post '/posts' do
  if session[:user].nil? # ログインしていない場合
    session[:message] = { key: 'danger', value: 'ログインしてください' } # フラッシュメッセージを代入
    redirect '/login'
  end
  title = params[:title]
  content = params[:content]
  if title.empty? || content.empty? # タイトルと内容が空欄だった場合
    session[:message] = { key: 'danger', value: '必須項目を入力してください' } # フラッシュメッセージを代入
    return redirect '/posts/new'
  end
  if params[:img] # 画像がある場合の処理
    tempfile = params[:img][:tempfile] # ファイルがアップロードされた場所
    save_to = "./public/images/#{params[:img][:filename]}" # ファイルを保存したい場所
    FileUtils.mv(tempfile, save_to)
    post = client.exec_params("insert into posts(user_id, title, content, image) values($1, $2, $3, $4) returning *", [session[:user]["id"], title, content, params[:img][:filename]]).to_a.first
  else # 画像がない場合の処理
    post = client.exec_params("insert into posts(user_id, title, content) values($1, $2, $3) returning *", [session[:user]["id"], title, content]).to_a.first
  end
  session[:message] = { key: 'success', value: '投稿しました' } # フラッシュメッセージを代入
  return redirect "/post/#{post['id']}"
end

get '/post/:id/edit' do
  if session[:user].nil? # ログインしていない場合
    session[:message] = { key: 'danger', value: 'ログインしてください' } # フラッシュメッセージを代入
    return redirect '/login'
  end
  @post = client.exec_params("select * from posts where id = $1", [params[:id]]).to_a.first
  if @post['user_id']  != session[:user]['id'] # 投稿したユーザーidとログイン中のユーザーのidが一致しない場合
    session[:message] = { key: 'danger', value: 'アクセス権限がありません' } # フラッシュメッセージを代入
    return redirect '/'
  end
  return erb :edit_post
end

put '/post/:id' do
  if session[:user].nil? # ログインしていない場合
    session[:message] = { key: 'danger', value: 'ログインしてください' } # フラッシュメッセージを代入
    redirect '/login'
  end
  post = client.exec_params("select * from posts where id = $1", [params[:id]])
  if post['user_id']  != session[:user]['id'] # 投稿したユーザーidとログイン中のユーザーのidが一致しない場合
    session[:message] = { key: 'danger', value: 'アクセス権限がありません' } # フラッシュメッセージを代入
    return redirect '/'
  end
  title = params[:title]
  content = params[:content]
  if params[:img]  # 画像がある場合の処理
    tempfile = params[:img][:tempfile]
    save_to = "./public/images/#{params[:img][:filename]}"
    FileUtils.mv(tempfile, save_to)
    client.exec_params("update posts set title = $1, content = $2, image = $3 where id = $4", [title, content, params[:img][:filename], params[:id]])
  else # 画像がない場合の処理
    client.exec_params("update posts set title = $1, content = $2 where id = $3", [title, content, params[:id]])
  end
  session[:message] = { key: 'success', value: '投稿を更新しました' } # フラッシュメッセージを代入
  return redirect "/posts/#{post['id']}"
end

delete '/post/:id' do
  if session[:user].nil? # ログインしていない場合
    session[:message] = { key: 'danger', value: 'ログインしてください' } # フラッシュメッセージを代入
    redirect '/login'
  end
  post = client.exec_params("select * from posts where id = $1", [params[:id]])
  if post['user_id']  != session[:user]['id'] # 投稿したユーザーidとログイン中のユーザーのidが一致しない場合
    session[:message] = { key: 'danger', value: 'アクセス権限がありません' } # フラッシュメッセージを代入
    return redirect '/'
  end
  client.exec_params("delete from posts where id = $1", [params[:id]])
  session[:message] = { key: 'danger', value: '投稿を削除しました' } # フラッシュメッセージを代入
  return redirect '/'
end

# 上記記載のルーティングに一致しなかった場合
not_found do
  return erb :not_found
end