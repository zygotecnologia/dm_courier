
# Rails Courier

[![Build Status](https://travis-ci.org/sumoners/rails_courier.svg?branch=master)](https://travis-ci.org/sumoners/rails_courier)
[![Gem Version](https://badge.fury.io/rb/rails_courier.svg)](http://badge.fury.io/rb/rails_courier)
[![security](https://hakiri.io/github/sumoners/rails_courier/master.svg)](https://hakiri.io/github/sumoners/rails_courier/master)
[![Test Coverage](https://codeclimate.com/github/sumoners/rails_courier/badges/coverage.svg)](https://codeclimate.com/github/sumoners/rails_courier/coverage)
[![Code Climate](https://codeclimate.com/github/sumoners/rails_courier/badges/gpa.svg)](https://codeclimate.com/github/sumoners/rails_courier)

Stick with just one Gem and be free to choose yuor email delivery service. Rails
Courier allows you to change easily the deliery method anytime you want.

## Rails Setup

First, add the gem to your Gemfile and run the `bundle` command to install it.

```ruby
gem 'rails_courier'
```

Second, set the delivery method in `config/environments/production.rb`.

```ruby
 config.action_mailer.delivery_method = :rails_courier
```

Third, create an initializer such as `config/initializers/rails_courier.rb` and
paste in the following code:

```ruby
RailsCourier.configure do |config|
  config.api_key = ENV['RAILS_COURIER_APIKEY']
  config.api = :sparkpost # Choose here the service you want to use
end
 ```

NOTE: If you don't already have an environment variable for delivery service API
key, don't forget to create one.

### Available configuration options

Option     | Default value     | Description
-----------|-------------------|------------------------------------------------------------
`api_key`  | ENV['RAILS_COURIER_API_KEY'] | Your service API key
`service`  | ENV['RAILS_COURIER_SERVICE'] | Your service API name. See [#Supported Services] for more information

## Development & Feedback

Questions or problems? Please use the issue tracker. If you would like to
contribute to this project, fork this repository. Pull requests appreciated.

This gem is based on the [mandrill_dm](https://github.com/mandrill_dm) gem.
