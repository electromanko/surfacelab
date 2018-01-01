# myapp.rb
require 'sinatra'
require 'bcrypt'
require 'sass'
require 'yaml'
require "./helpers/application_helper.rb"
require "./slconfig.rb"
require "./sldconfig.rb"
#require "../test/testDSL.rb"

#require 'logger'

RO_ROOT='/ro'
RW_REMOUNT_DIRECTORIES = ['/etc', '/var/lib/cloud9/surfacelab/ruby-surfacelab/web/db']

CONFIG_FILE_JSON = 'db/settings.json'
CONFIG_FILE_YAML = 'db/settings.yaml'
DAEMON_CONFIG_FILE_YAML = 'db/suladconf.yaml'
DAEMON_CONFIG_FILE_SLD="/etc/sulad.conf"
NETWORK_CONFIG_FILE = '/etc/network/interfaces.d/10-surfacelab'

use Rack::Session::Cookie
enable :logging, :dump_errors, :raise_errors
set :haml, :format => :html4

userTable = {}
mainMenu = { 
          :config => 'Config',
          #:terminal => 'Terminal',
          :daemon => 'Daemon',
          #:help => 'Help'
}


#testDSL = TestDSL.new
slconfig = SLConfig.new
slconfig.load_config(CONFIG_FILE_YAML, :YAML)
config = slconfig.config
#begin
  sldconfig = SLDConfig.load_config(DAEMON_CONFIG_FILE_YAML)
#rescue Exception => e  
#  puts e.message  
#end
daemon_parameter={
  :speed => [2400,4800,9600,19200,38400,57600,115200,460800,500000,576000,921600,1000000,1152000,1500000,2000000],
  :data_bits => [5,6,7,8],
  :parity => ['n', 'o', 'e'],
  :stop_bits => [1,2],
  :leds => [0,71,70,86,88,87,89],
  :leds_label => {0=>'none',71=>'1',70=>'2',86=>'3',88=>'4',87=>'5',89=>'6'}
}

password_salt = BCrypt::Engine.generate_salt
password_hash = BCrypt::Engine.hash_secret(config['admin']['items']['password']['value'], password_salt) #"surface"

helpers ApplicationHelper

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

userTable[config['admin']['items']['user']['value']] = { #"surface"
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
=begin
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
=end
get "/daemon" do
  if login?
    haml :daemon, :locals => {:item => :daemon, :config => sldconfig, :daemon_parameter => daemon_parameter}
  else
    redirect "/login"
  end
end

post "/daemon/:num" do
  #haml :test, :locals => {:item => :daemon}
#=begin
  conf= sldconfig['port'][params['num'].to_i]
  if login?
    conf['tcp_port'] = params[:tcp_port].to_i
    conf['sys_path'] = params[:sys_path].to_s
    conf['speed'] = params[:speed][0].to_i
    conf['data_bits'] = params[:data_bits][0].to_i
    conf['parity'] = params[:parity][0].to_s
    conf['stop_bits'] = params[:stop_bits][0].to_i
    conf['delay_us'] = params[:delay_us].to_i
    conf['delay_segment'] = params[:delay_segment].to_i
    if params[:tx_led][0].to_i>0
      conf['tx_led'] = params[:tx_led][0].to_i
    else 
      conf['tx_led'] = nil
    end
    
    if params[:rx_led][0].to_i>0
      conf['rx_led'] = params[:rx_led][0].to_i
    else 
      conf['rx_led'] = nil
    end
    
    conf['gpio_high'] = params['gpio_high'].split(",").map { |s| s.to_i }
    conf['gpio_low'] = params['gpio_low'].split(",").map { |s| s.to_i }
    write_unprotect(RO_ROOT, RW_REMOUNT_DIRECTORIES) do
      SLDConfig.save_config( sldconfig,DAEMON_CONFIG_FILE_YAML)
      SLDConfig.save_config( sldconfig,DAEMON_CONFIG_FILE_SLD, :SLD)
    end
    #system("cp #{DAEMON_CONFIG_FILE_SLD} /etc/sulad.conf")
    sleep 1
    system("/etc/init.d/sulad stop")
    sleep 2
    system("/etc/init.d/sulad start")
    redirect "/daemon"
  else 
    redirect "/login"
  end
#=end
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
    write_unprotect(RO_ROOT, RW_REMOUNT_DIRECTORIES) do
      slconfig.save_config(CONFIG_FILE_YAML, :YAML)
      if category=='network'
        SLConfig.save_network_confg(slconfig.config,"eth0",NETWORK_CONFIG_FILE)
      end
    end
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

post "/dsl_reset" do
  if login?
    system( "reboot" )
  end 
  haml :test
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
@@daemon
-i=0
-config["port"].each do |port|
  %h1=port["name"]
  %form(action="/daemon/#{i}" method="post")
    %div
      %label(for="tcp_port") TCP port:
      %input(type="text" name="tcp_port" value="#{port['tcp_port']}")
    %div
      %label(for="sys_path") System path:
      %input(type="text" name="sys_path" value="#{port['sys_path']}")
    %div
      %label(for="speed") speed:
      %select(size="1" name="speed[]")
        -daemon_parameter[:speed].each do |baud|
          -if baud==port['speed'].to_i
            %option(value="#{baud}" selected="selected")=baud
          -else
            %option(value="#{baud}")=baud
    %div
      %label(for="data_bits") data bits:
      %select(size="1" name="data_bits[]")
        -daemon_parameter[:data_bits].each do |n|
          -if n==port['data_bits'].to_i
            %option(value="#{n}" selected="selected")=n
          -else
            %option(value="#{n}")=n
    %div
      %label(for="parity") parity:
      %select(size="1" name="parity[]")
        -daemon_parameter[:parity].each do |parity|
          -if parity==port['parity'].to_s
            %option(value="#{parity}" selected="selected")=parity
          -else
            %option(value="#{parity}")=parity
    %div
      %label(for="stop_bits") stop:
      %select(size="1" name="stop_bits[]")
        -daemon_parameter[:stop_bits].each do |stop|
          -if stop==port['stop_bits'].to_i
            %option(value="#{stop}" selected="selected")=stop
          -else
            %option(value="#{stop}")=stop
    %div
      %label(for="delay_us") delay(us):
      %input(type="text" name="delay_us" value="#{port['delay_us']}")
    %div
      %label(for="delay_segment") delay segment:
      %input(type="text" name="delay_segment" value="#{port['delay_segment']}")
    %div
      %label(for="tx_led") tx led:
      %select(size="1" name="tx_led[]")
        -daemon_parameter[:leds].each do |led|
          -if led==port['tx_led'].to_i
            %option(value="#{led}" selected="selected")=daemon_parameter[:leds_label][led]
          -else
            %option(value="#{led}")=daemon_parameter[:leds_label][led]
    %div
      %label(for="rx_led") rx led:
      %select(size="1" name="rx_led[]")
        -daemon_parameter[:leds].each do |led|
          -if led==port['rx_led'].to_i
            %option(value="#{led}" selected="selected")=daemon_parameter[:leds_label][led]
          -else
            %option(value="#{led}")=daemon_parameter[:leds_label][led]
    %div
      %label(for="gpio_high") gpio high:
      -if port['gpio_high'].nil?
        -gpio=""
      -else
        -gpio=port['gpio_high'].join(',')
      %input(type="text" name="gpio_high" value="#{gpio}")
    %div
      %label(for="gpio_low") gpio low:
      -if port['gpio_low'].nil?
        -gpio=""
      -else
        -gpio=port['gpio_low'].join(',')
      %input(type="text" name="gpio_low" value="#{gpio}")
    %input(type="submit" value="Set")
    %input(type="reset" value="Restore")
    -i+=1
    %hr
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
