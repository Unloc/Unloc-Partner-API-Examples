# encoding: UTF-8

require 'sinatra'
require 'httparty'
require "openssl"

# Fill in your credentials here:
$invitee = '<phone number>'
$api_key = '<api key>'
$hmac_secret = '<hmac secret>'
$partner_id = '<partner id>'

# Requests and URL setup
$base_url = "https://api.unloc.app/v1"
$headers = {'Authorization': "Bearer #{$api_key}"}
$app_scheme = 'ai.unloc.pro://'

# Creates an url to be used to open the Unloc Pro app.
# Pass a valid key ID.
def app_scheme_url(key_id)
    return_uri = "https://#{request.host}"
    params = "id=#{key_id}&r=#{return_uri}&n=#{$partner_id}"
    s = OpenSSL::HMAC.hexdigest('SHA256', $hmac_secret, params)
    return "#{$app_scheme}use-key?#{params}&s=#{s}"
end

# Get the locks available to the configured partner
def get_locks
    HTTParty.get("#{$base_url}/partners/#{$partner_id}/locks", {headers: $headers}).parsed_response['locks']
end

# Creates a key for the lock with the provided 
def create_key(lock_id)
    body = {
        'lockId': lock_id, 
        'start': Time.now.utc, 
        'end': (Time.now + 24*60*60).utc, 
        'msn': $invitee
    }
    
    HTTParty.post("#{$base_url}/partners/#{$partner_id}/keys", {headers: $headers, body: body}).parsed_response['id']
end

# Get the key details for the provided key id
def key_details(key_id)
    HTTParty.get("#{$base_url}/partners/#{$partner_id}/keys/#{key_id}", {headers: $headers}).parsed_response
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
        @key_id = create_key(lock['id'])
        @key_details = key_details(@key_id)
        @open_app_url = app_scheme_url(@key_id)
        erb :key_id
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

@@ key_id
<h1>Here is your key:</h1>
<% @key_details.each do |k,v| %>
    <p><%= k %>: <%= v %></p>
<% end %>

<p><a href="<%= @open_app_url %>">Use key</a></p>
<p><a href="/">Back to locks</a></p>