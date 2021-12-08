# TAlgebra

## Installation

Add this line to your application's Gemfile:

```ruby
gem 't_algebra'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install t_algebra

## Usage

t_algebra brings the basic categorical concepts of Functor, Applicative, and Monad into ruby, along with a handful of common instances. 

Let's walk through `TAlgebra::Monad::Maybe`, the monad representing optional results. Typically in ruby we have a method
which may return a value or nil should some underlying data be absent. For example `user.city` may return `nil` should the
user not have entered their city. Working with these possible `nil` values can be a source of bugs and a source of code
complexity. The following code is illustrative:

```
# @return [String, nil]
def get_address(user)
    street = user.street
    return unless street
    
    city = user.city
    return unless city
    
    state = user.state
    return unless state
    state = state.upcase

    "#{street}, #{city} #{state}" 
end
```

The class `TAlgebra::Monad::Maybe` wraps a result which may or may not be nil, and uses the Monad tech of `bind` + `fmap` to 
sensibly manipulate that result. The below example uses `run/yield` notation (analagous to Haskell `do` notation or js `async/await`)
to reproduce the same functionality:

```
# @return [TAlgebra::Monad::Maybe]
def get_address(user)
    TAlgebra::Monad::Maybe.run do |y|
        m_user = just(user)
        street = y.yield { m_user.fetch(:street) }
        city = y.yield { m_user.fetch(:city) }
        state = y.yield { m_user.fetch(:state) }
        "#{street}, #{city} #{state.upcase}"
    end
end
```

This basic Maybe functionality extends neatly into the `Either` monad, the monad representing results or errors, and
subsequently `Parser` which can validate and map over complex data structure.

```
# @return [TAlgebra::Monad::Parser]
def get_address(user)
    TAlgebra::Monad::Parser.run do |y|
        # validate street is present with `#fetch!`
        street = y.yield { fetch!(user, :street) }
        
        # validate that the city is a string with is `#is_a?`
        city = y.yield { fetch!(user, :city).is_a?(String) }
        
        # validate that the state is a 2 letter long string with `#validate` 
        # and transform to all caps with `#fmap`
        state = y.yield do 
            fetch!(user, :state)
                .is_a?(String)
                .validate("Is 2 letter code"){ |state| state.length == 2 }
                .fmap(&:upcase)
        end
        
        "#{street}, #{city} #{state}"
    end
end
```

### Defining your own examples

Say we had a class `ExtAPI` representing a an external api result or http error. (Similar to the Either monad.) We could implement this as a monad as 
follows:

```
class ExtAPI
    include TAlgebra::Monad
    
    class << self
        def call(verb, path)
            ... make api cal
        rescue => e
            new(http_error: {e.status, e.message})
        end
            
        #Implement Applicative's `.pure` interface
        def pure(a)
            new(success: a)        
        end
    end
    
    #Implement Monad's `#bind` interface
    def bind
        return new(http_error: http_error) if http_error
        yield(success)
    end
    
    ...
end
```

And it could be used like:

```
def user_cities
    ExtAPI.run do |y|
        users = y.yield { call('GET', '/users') }
        profiles = y.yield { call('GET', "/users/profile?id=#{users.map(&:id).to_json}" } 
        profiles.map(&:city).uniq
    end
end
```

(Note that while the concept of Promise is monadic, the above ExtAPI implementation is entirely synchronous.) Should
either of the two calls fail, this method will return that error status and message to be handled by the client code.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/t_algebra. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/t_algebra/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TAlgebra project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/afg419/t_algebra/blob/master/CODE_OF_CONDUCT.md).
