# encoding: UTF-8

require 'sinatra'
require 'httparty'
require "openssl"

# Fill in your credentials here:
$partner = '<partner id>'
$invitee = '<phone number>'
$api_key = '<api key>'
$hmac_secret = '<hmac secret>'

# Requests and URL setup
$base_url = "https://api.unloc.app/v1"
$headers = {'Authorization': "Bearer #{$api_key}"}
$app_scheme = 'ai.unloc.pro://'

# Generates HMAC from the provided data in hex
def hmac_hex(data)
    OpenSSL::HMAC.hexdigest('SHA256', $hmac_secret, data)
end

# Creates an url to be used to open the Unloc Pro app.
# Pass a valid key ID.
def app_scheme_url(key_id)
    parameters = "id=#{key_id}&r=https://#{request.host}&n=#{$partner}"
    hmac = hmac_hex(parameters)

    "#{$app_scheme}use-key?#{parameters}&s=#{hmac}"
end

# Get the locks available to the configured partner
def get_locks
    HTTParty.get("#{$base_url}/partners/#{$partner}/locks", {headers: $headers}).parsed_response['locks']
end

# Creates a key for the lock with the provided 
def create_key(lock_id)
    body = {
        'lockId': lock_id, 
        'start': Time.now.utc.to_date, 
        'end': (Time.now + 24*60*60).utc.to_date, 
        'msn': $invitee
    }
    
    HTTParty.post("#{$base_url}/partners/#{$partner}/keys", {headers: $headers, body: body}).parsed_response['id']
end

get '/' do
    @locks = get_locks
    unless @locks.nil?
        erb :index
    else
        halt 404
    end
end

get '/lock/:id' do
    begin
        lock = get_locks.find {|lock| lock['id'] == params['id']}
    rescue
        halt 404
    end

    unless lock.nil?
        @lock_id = create_key(lock['id'])
        @open_app_url = app_scheme_url(@lock_id)
        erb :lock_id
    else 
        halt 406
    end
end

not_found do
    'This is nowhere to be found.'
end

__END__

@@ layout
<!DOCTYPE html>
<html>
  <body>
    <%= yield %>
  </body>
</html>

@@ index
<h1>Locks</h1>
<ul>
    <% @locks.each do |lock| %>
        <li><%= lock['id'] %> - <%= lock['name'] %>  <a href="/lock/<%= lock['id'] %>">Create key</a></li>
    <% end %>
</ul>

@@ lock_id
<h1>This is key: <%= @lock_id %></h1>
<form action="<%= @open_app_url %>" target="_blank">
    <input type="submit" value="Use key" />
</form>