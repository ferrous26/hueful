# Hueful

A library for experimenting with and orchestrating Philips Hue lights.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hueful'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hueful


## Usage

```ruby
require 'hueful'

# first you need to find a Hue bridge; we try N-uPnP by default;
# but you will want to use the SSDP method on a closed network
bridges = Hueful.discover
bridge = bridges.first

# after finding a bridge you can save the IP address to a file and
# use the cached method for discovery next time, it's much faster
bridge.cache_config

# to actually do anything useful with the API you need an auth
# token, which can
client = bridge.new_client 'hueful_client'

# if creating a client fails, e

# now that you have an auth token, you can save that to a file and
# restore that next time to avoid finding the bridge and creating
# a new token again
client.cache_config
```

If you took advantage of configuration caching, then next time you run
Hueful you can restore the session

```ruby
client = Hueful.load_cached_client


# after configuration is figured out, the fun can begin
lights = client.lights
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## TODO

- [ ] Decide on a web mocking framework and write tests
- [ ] Light subsets and supersets
- [ ] Dynamic light sets (light query language?)
- [ ] Persistent special properties (e.g. specific light should always be set 20% lower)


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ferrous26/hueful.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
