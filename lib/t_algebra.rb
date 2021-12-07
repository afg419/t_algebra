require_relative "t_algebra/version"
require_relative "t_algebra/functor"
require_relative "t_algebra/applicative"
require_relative "t_algebra/monad"
require_relative "t_algebra/monad/errors"
require_relative "t_algebra/monad/maybe"
require_relative "t_algebra/monad/either"
require_relative "t_algebra/monad/list"
require_relative "t_algebra/monad/reader"
require_relative "t_algebra/monad/parser"

module TAlgebra
  class Error < StandardError; end
end
