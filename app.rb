# encoding: UTF-8

require 'sinatra'
require 'httparty'

$partner = '<partner id>'
$invitee = '<phone number>'
$api_key = '<api key>'
$hmac_secret = '<hmac secret>'
$app_scheme = 'ai.unloc.pro://'
$return_url = '<to be resolved>'

class ApiClient
    include HTTParty

    base_uri "https://api.unloc.app/v1"

    @headers = {'Authorization': "Bearer #{$api_key}"}

    def self.locks
        self.get("/partners/#{$partner}/locks", {headers: @headers}).parsed_response['locks']
    end
    
    def self.create_key(lock_id)
        body = {
            'lockId': lock_id, 
            'start': Time.now.utc.to_date, 
            'end': (Time.now + 24*60*60).utc.to_date, 
            'msn': $invitee
        }
        
        self.post("/partners/#{$partner}/keys", {headers: @headers, body: body}).parsed_response['id']
    end
    
end

def app_scheme_url(key_id)
    "#{$app_scheme}use-key?id=#{key_id}&r=#{$return_url}&n=#{$partner}&s=#{$hmac_secret}"
end

get '/' do
    @locks = ApiClient.locks
    erb :index
end

get '/lock/:id' do
    locks = ApiClient.locks
    begin
        lock = locks.find {|lock| lock['id'] == params['id']}
    rescue
        halt 404
    end

    unless lock.nil?
        @lock_id = ApiClient.create_key(lock['id'])
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