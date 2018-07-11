# Unloc Partner API Example

This is an example implementation for how to use the Unloc API as a _partner_. As a _partner_ you will want ot list the locks you can generate keys for. The example demonstrates how to fetch the locks, generate keys and create signed url's for using the keys with the Unloc Work app.

### Up and running
The example is built using Ruby and Sinatra as a tiny web page. To get up and running make sure you have `Ruby` (2.5.1p57 was used here) installed on your machine.

1. Install `bundler` if needed `$ gem install bundler`
2. Run `$ bundle install`
3. Fill inn your credentials in the `app.rb` file
4. To start the server run `shotgun config.ru`

To make the redirect url (the url for returning from the Unloc Work to the web page after key is used) work you can use a tool like [ngrok](https://ngrok.com).

### Usage
When the credentials if filled in correctly, you will find the list of available lock at the root page. When tapping create key, a key will be generated together with a signed url for opening the Unloc Work app. 