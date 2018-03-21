# myapp.rb
require 'sinatra'
require 'bcrypt'
require 'sass'
require "./helpers/application_helper.rb"
require "./slconfig.rb"
require "../test/testDSL.rb"

#require 'logger'


CONFIG_FILE_JSON = 'db/settings.json'
CONFIG_FILE_YAML = 'db/settings.yaml'

use Rack::Session::Cookie
enable :logging, :dump_errors, :raise_errors
set :haml, :format => :html4

userTable = {}
mainMenu = { 
          :config => 'Config',
          :terminal => 'Terminal',
          :help => 'Help'
}


testDSL = TestDSL.new
slconfig = SLConfig.new
slconfig.load_config(CONFIG_FILE_YAML, :YAML)
config = slconfig.config

password_salt = BCrypt::Engine.generate_salt
password_hash = BCrypt::Engine.hash_secret("surface", password_salt)

#helpers ApplicationHelper

helpers do
  
  def login?
    if session[:username].nil?
      return false
    else
      return true
    end
  end
  
  def username
    return session[:username]
  end

  def title(value = nil)
    @title = value if value
    @title ? "SL | #{@title}" : "SL"
  end 
  
end


before do

userTable["surface"] = {
    :salt =>  password_salt,
    :passwordhash => password_hash
}
    
title mainMenu[request.path_info[1..-1]]
@mainMenu = mainMenu

end

["/", "/config"].each do |path|
  get path do
    #puts @config
    if login? 
      haml :config, :locals => {:config => config, :item => :config}
    else
      redirect "/login"
    end
  end
end

get "/terminal" do
  if login? 
    haml :terminal, :locals => {:item => :terminal, :testDSL => testDSL}
  else
    redirect "/login"
  end
end

post "/terminal" do
  if params[:action] == "Start"
    testDSL.start(params[:size]) unless params[:size].nil?
  elsif params[:action] == "Loop"
    testDSL.start(0, true)
  else
    testDSL.stop
  end
  #haml :test, :locals => {:item => :terminal}
  haml :terminal, :locals => {:item => :terminal, :testDSL => testDSL}
end

get "/login" do
  haml :login
end

post "/login" do
  if userTable.has_key?(params[:username])
    user = userTable[params[:username]]
    if user[:passwordhash] == BCrypt::Engine.hash_secret(params[:password], user[:salt])
      session[:username] = params[:username]
      redirect "/"
    end
  end
  haml :error
end

post "/settings/:category" do
=begin
  config[params['category']]["items"].each do |k,v|
    unless params[k].nil?
      if v["value"].is_a?(TrueClass) || v["value"].is_a?(FalseClass)
        v["value"] = params[k].to_bool
      else
        v["value"] = params[k]
      end
    end
  end
=end
  category = params['category']
  params['category'] = nil
  slconfig.set_categoty!(category, params)
  #haml :test
  redirect "/"
end

post "/settings/restore/:category" do
  slconfig.restore_default!(params['category'])
  config = slconfig.config
  #haml :test
  redirect "/"
end

get "/logout" do
  session[:username] = nil if login?
  redirect "/"
end


post "/poweroff" do
  if login?
    session[:username] = nil
    system( "poweroff" )
  end
  haml :test
  
end

post "/reboot" do
  if login?
    session[:username] = nil
    system( "reboot" )
  end 
  haml :test
end

post "/speed_change" do
  
  system("echo \"-D /dev/ttyO5 -S 19200 -P 8898 --segment-delay 2000 --event-rx-led 70 --event-tx-led 71\" > /etc/sulad.conf")
  case params["speed"]
    when "115200"
      system("echo \"-D /dev/ttyO2 -S 115200 -P 8899 -s 2 --event-rx-led 72 --event-tx-led 73 --gpio-low 110 --gpio-low 113\" >> /etc/sulad.conf")
    when "1500000"
      system("echo \"-D /dev/ttyO2 -S 1500000 -P 8899 -s 2 --event-rx-led 72 --event-tx-led 73 --gpio-high 110 --gpio-high 113\" >> /etc/sulad.conf")
  end
  sleep 1
  system("/etc/init.d/sulad stop")
  sleep 3
  system("/etc/init.d/sulad start")
  haml :test, :locals => {:item => :terminal}
end

# style="text-align:center"

__END__
@@layout
!!! 5
%html
  %head
    %title Surface Lab Auth
    :sass
      .main_menu
        text-align: center
        ul
          text-align: center
          list-style: none
          margin: 0
          padding-left: 0
          li
            display: inline-block
            a
              margin: 2px
              padding: 5px
              display: block
              text-decoration: none
              font-size: 26px
              background: #d0d0d0
            a:hover
              background: #3399ff
            a#current
              background: #3399ff
      .welcome
        position: absolute
        top: 0 
        right: 10px
        ul
          text-align: center
          list-style: none
          li
            display: inline-block 
            a
              display: block
              margin: 2px
              padding: 5px
            p
              display: block
              margin: 2px
              padding: 5px
  %body
    -if login?
      .main_menu
        %ul
          -@mainMenu.each do |key,val|
            %li
              -if item == key
                %a{:id => "current", :href => "#{key}" }= val
              -else
                %a{:href => "#{key}"}= val
      .welcome
        %ul
          %li
            %p= "Welcome #{username}!"
          %li
            %a{:href => "/logout"} Logout
    %div(align="center")
      =yield
@@config
-config.each do |key,val|
  %h2= val["name"]
  %form{:action => "/settings/#{key}", :method => "post"}
    %table
      -val["items"].each do |k,v|
        %tr
          %td= v["name"]
          %td
            -valval=v["value"]
            -if valval.is_a?(TrueClass)
              %input(id="#{k}n" type="hidden" name="#{k}" value="false")
              %input(id="#{k}" type="checkbox" name="#{k}" value="true" checked="checked" autocomplete="off")
            -elsif valval.is_a?(FalseClass)
              %input(id="#{k}n" type="hidden" name="#{k}"  value="false")
              %input(id="#{k}" type="checkbox" name="#{k}" value="true" autocomplete="off")
            -else
              %input(id="#{k}" type="text" name="#{k}" value="#{valval}")
          %td= valval
    %input(type="submit" value="Set")
    %input(type="reset" value="Restore")
    %input(type="submit" value="Default" formaction="/settings/restore/#{key}")
%form(action="/poweroff" method="post")    
  %input(type="submit" value="Poweoff")
%form(action="/reboot" method="post")    
  %input(type="submit" value="Reboot")
%form(action="/speed_change" method="post")
  %input(type="radio" name="speed" value="115200") 115200
  %input(type="radio" name="speed" value="1500000") 1500000
  %input(type="submit" value="Change")
@@terminal
%h1 IO terminal
%form(action="/terminal" method="post")
  %div
    %label(for="sizeBlock") Size block:
    %input(type="radio" name="size" value="1000") 1k
    %input(type="radio" name="size" value="1000000") 1m
    %input(type="radio" name="size" value="10000000") 10m
    %input(type="radio" name="size" value="100000000" ) 100m
    %input(type="radio" name="size" value="-1" ) Unlim
  %div#here
    -if testDSL.status[:state] !="stoped"
      %input(type="submit" name="action" value="Start" disabled)
      %input(type="submit" name="action" value="Stop")
      %input(type="submit" name="action" value="Loop" disabled)
    -else
      %input(type="submit" name="action" value="Start")
      %input(type="submit" name="action" value="Stop" disabled)
      %input(type="submit" name="action" value="Loop")
    %p= testDSL.status[:state]
    %p= testDSL.status
    -if testDSL.status[:state] =="started"
      :javascript
        setTimeout(function(){
          window.location = window.location.href;
        }, 2000);
    
@@login
%h1 SL Admin Panel
%form(action="/login" method="post")
  %div
    %label(for="username")Username:
    %input#username(type="text" name="username")
  %div
    %label(for="password")Password:
    %input#password(type="password" name="password")
  %div
    %input(type="submit" value="Login")
    %input(type="reset" value="Clear")
  %p
    %a{:href => "/signup"} Signup
@@signup
%p Enter the username and password!
%form(action="/signup" method="post")
  %div
    %label(for="username")Username:
    %input#username(type="text" name="username")
  %div
    %label(for="password")Password:
    %input#password(type="password" name="password")
  %div
    %label(for="checkpassword")Password:
    %input#password(type="password" name="checkpassword")
  %div
    %input(type="submit" value="Sign Up")
    %input(type="reset" value="Clear")
@@error
%p Wrong username or password
%p Please try again!
@@test
%h1 Test
%h2= params
@@errrrr

=begin

#############################################################
require "sinatra/base"
require "./helpers/application_helper.rb"
require "bcrypt"
require "twitter"
require "twitter-text"
require "nokogiri"
require "open-uri"



class LandingApp < Sinatra::Base
#enable :sessions
use Rack::Session::Cookie

helpers ApplicationHelper

twclient = Twitter::REST::Client.new do |config|
  config.consumer_key        = "yXvb2uIaZ8Gx7A9ma2D2aWwtt"
  config.consumer_secret     = "PQZCOZgvSOGR1LNJbsMB8rfnp051yr0HtUf276Ic5i3KLE9OBg"
  config.access_token        = "3102999687-9WQXF0y3xlEJTexmb7SV2TfCMVLjuwbG0yoBoQM"
  config.access_token_secret = "2iiwe7UwWnEYILvASSX6oWar2suLb6LaYarUYfHgdL5OK"
end

userTable = {}

password_salt = BCrypt::Engine.generate_salt
password_hash = BCrypt::Engine.hash_secret("romanko", password_salt)

userTable["roman"] = {
    :salt =>  password_salt,
    :passwordhash => password_hash
}

before do
MainMenu = {
        'calcs' => 'Calcs',
        'photo' => 'Photo',
        'lab' => 'Lab',
        'lib' => 'Lib',
        'about' => 'About'

}
end

before do
        title MainMenu[request.path_info[1..-1]]
end

get "/" do
        erb :index
end

get "/about" do
        #title "About"
        erb :about
end

get "/calcs" do
        #title "Calcs"
        erb :calcs
end

get "/photo" do
        erb :photo
end

get "/lab" do

        erb :lab, :locals => {:twc => twclient}
end

get "/lib" do
        erb :lib
end

get "/login" do
        erb :login
end

post "/login" do
  if userTable.has_key?(params[:username])
    user = userTable[params[:username]]
    if user[:passwordhash] == BCrypt::Engine.hash_secret(params[:password], user[:salt])
      session[:username] = params[:username]
      redirect "/"
    end
  end
  erb :not_found
end

get "/logout" do
  session[:username] = nil
  redirect "/"
end

not_found do
        status 404
        erb :not_found
end

#get '/session/:value' do
#  session['value'] = params['value']
#end

end
=end
