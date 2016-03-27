
# DM Courier

[![Build Status](https://travis-ci.org/sumoners/dm_courier.svg?branch=master)](https://travis-ci.org/sumoners/dm_courier)
[![Gem Version](https://badge.fury.io/rb/dm_courier.svg)](http://badge.fury.io/rb/dm_courier)
[![security](https://hakiri.io/github/sumoners/dm_courier/master.svg)](https://hakiri.io/github/sumoners/dm_courier/master)
[![Test Coverage](https://codeclimate.com/github/sumoners/dm_courier/badges/coverage.svg)](https://codeclimate.com/github/sumoners/dm_courier/coverage)
[![Code Climate](https://codeclimate.com/github/sumoners/dm_courier/badges/gpa.svg)](https://codeclimate.com/github/sumoners/dm_courier)

Stick with just one Gem and be free to choose your email delivery service.  DM
Courier (Delivery Method Courier) allows you to easily change the deliery method
as you wish.

## Rails Setup

First, add the gem to your Gemfile and run the `bundle` command to install it.

```ruby
gem 'dm_courier'
```

Second, set the delivery method in `config/environments/production.rb`.

```ruby
 config.action_mailer.delivery_method = :dm_courier
```

Third, create an initializer such as `config/initializers/dm_courier.rb` and
paste in the following code:

```ruby
DMCourier.configure do |config|
  config.api_key = ENV['DM_COURIER_APIKEY']
  config.service_name = :mandrill # Choose here the service you want to use
end
 ```

NOTE: If you don't already have an environment variable for delivery service API
key, don't forget to create one.

### Available configuration options

Any option with Mailer Support can be used inside the mailer like:

```ruby
class MyMailer < ActionMailer::Base
  default track_opens: false

  def notify_user(email)
    mail(auto_html: false, inline_css: true)
  end
end
```

Option     | Mailer Support | Description
-----------|----------------|-------------
`api_key`  | false | Your service API key<br />**Default:** `ENV['DM_COURIER_API_KEY']`
`service_name`  | false | Your service API name.<br />**Default:** `ENV['DM_COURIER_SERVICE']`
`async` | false | If the message with be sent asynchronous (depends on the service support)<br />**Default:** false<br />**Services:** mandrill
`from` | true | A default from address for all emails<br />**Services:** all
`auto_html` | true |  whether or not to automatically generate an HTML part for messages that are not given HTML<br />**Services:** mandrill
`auto_text` | true | whether or not to automatically generate a text part for messages that are not given text<br />**Services:** mandrill
`important` | true | whether or not this message is important, and should be delivered ahead of non-important messages<br />**Default**: false<br />**Services:** mandrill
`inline_css`  | true | whether or not to automatically inline all CSS styles provided in the message HTML - only for HTML documents less than 256KB in size<br />**Services:** mandrill, sparkpost
`track_clicks` | true | whether or not to turn on click tracking for the message<br />**Services:** mandrill, sparkpost
`track_opens` | true | whether or not to turn on open tracking for the message<br />**Services:** mandrill, sparkpost
`track_url_without_query_string` | true | whether or not to strip the query string from URLs when aggregating tracked URL data<br />**Services:** mandrill
`log_content` | true  |  set to false to remove content logging for sensitive emails<br />**Services:** mandrill
`bcc_address` | true  | an optional address to receive an exact copy of each recipient's email<br />**Services:** mandrill
`return_path_domain` | true | a custom domain to use for the messages's return-path<br />**Services:** mandrill, sparkpost
`signing_domain` | true | a custom domain to use for SPF/DKIM signing (for "via" or "on behalf of" in email clients)<br />**Services:** mandrill
`subaccount` | true  | the unique id of a subaccount - must already exist or will fail with an error<br />**Services:** mandrill
`tracking_domain` | true | a custom domain to use for tracking opens and clicks<br />**Services:** mandrill
`tags` | true | an array of string to tag the message with. Stats are accumulated using tags, though we only store the first 100 we see, so this should not be unique or change frequently. Tags should be 50 characters or less. Any tags starting with an underscore are reserved for internal use and will cause errors.<br />**Services:** mandrill

## Services

### Mandrill

### SparkPost

The options were choosen to create an abstraction layer above the original
service API. Because of that some options have different names:

- **return_path_domain**: Is called **return_path** on SparkPost
- **track_opens**: Is called **open_tracking** on SparkPost
- **track_clicks**: Is called **click_tracking** on SparkPost

> TODO: Sparkpost service implementation does not support BCC emails yet.

## Development & Feedback

Questions or problems? Please use the issue tracker. If you would like to
contribute to this project, fork this repository. Pull requests appreciated.

This gem is based on the [mandrill_dm](https://github.com/mandrill_dm) gem.
