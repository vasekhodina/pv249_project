require './fio_helper'
require './database_helper'

require 'sinatra'
require 'slim'

include FioHelper

database = DatabaseHelper.new
user = ''

use Rack::Auth::Basic, 'Restricted Area' do |username, password|
  database.check_user(username, password)
  user = username
end

get '/' do
  @logged_user = user
  @account = database.get_account_info()
  slim :app
end

get '/admin' do
  @users = database.get_users
  slim :admin
end

post '/admin/create' do
  database.create_user(params['username'], params['password'])
  redirect '/admin'
end

post '/admin/delete/:username' do
  database.delete_user(params['username'])
  redirect '/admin'
end

get '/:filter' do
  @logged_user = user
  if params['filter'] == 'all'
    @transactions = database.all_trns()
  elsif params['filter'] == 'positive'
    @transactions = database.positive_trns()
  elsif params['filter'] == 'negative'
    @transactions = database.negative_trns()
  else
    redirect '/'
  end
  slim :transactions
end

post '/upload/:id' do
  if params[:file]
    @filename = params[:file][:filename]
    file = params[:file][:tempfile]

    File.open("./public/uploads/#{@filename}", 'wb') do |f|
      f.write(file.read)
    end

    database.upload_invoice(params['id'],
                                  "./public/uploads/#{@filename}")
  end
  slim :confirmation
end

get '/download/:id' do
  file = database.get_filepath(params['id'])
  send_file(file, :disposition => 'attachment')
end

post '/delete/:id' do
  file = database.get_filepath(params['id'])
  File.delete(file)
  database.delete_invoice(params['id'])
  slim :confirmation
end

get '/confirmation' do
  slim :confirmation
end
