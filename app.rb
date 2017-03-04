require './fio_helper'
require './database_helper'

require 'sinatra'
require 'slim'

include FioHelper

##
# Sinatra application configuration
# This is the main file of the invoice reminder application

database = DatabaseHelper.new
user = ''

##
# Using Rack functionality for basic authentication
use Rack::Auth::Basic, 'Restricted Area' do |username, password|
  database.check_user(username, password)
  user = database.get_user(username)
end

##
# Show dashboard page
get '/' do
  @logged_user = user
  @account = database.get_account_info()
  slim :app
end

##
# Show administration page, where the admin sees the list of admins and users
get '/admin' do
  @logged_user = user
  @users = database.get_users
  slim :admin
end

##
# Route called to create new users and administrators, ie. new user accounts
post '/admin/create' do
  database.create_user(params['username'], params['password'], params['admin'])
  redirect '/admin'
end

##
# Post method called to change user account into admin account
post '/admin/make_admin/:username' do
  database.update_user(params['username'], true)
  redirect '/admin'
end

##
# Past method called to change admin account to user account, ie. lose admin access
post '/admin/make_user/:username' do
  database.update_user(params['username'], false)
  redirect '/admin'
end

##
# Method called to delete user/admin account
post '/admin/delete/:username' do
  database.delete_user(params['username'])
  redirect '/admin'
end

##
# Route to page with transactions depending on the variable, it can show all, negative
# or positive transactions
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

##
# Post route for uploading a file with invoice, or any other information to transaction
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

##
# Get method for downloading previously uploaded files
get '/download/:id' do
  file = database.get_filepath(params['id'])
  send_file(file, :disposition => 'attachment')
end

##
# Method for deleting previously uploaded file
post '/delete/:id' do
  file = database.get_filepath(params['id'])
  File.delete(file)
  database.delete_invoice(params['id'])
  slim :confirmation
end

##
# Route showing a confirmation page after file has been uploaded
get '/confirmation' do
  @logged_user = user
  slim :confirmation
end
