module TAlgebra
  module Monad
    class Maybe
      include TAlgebra::Monad

      NOTHING = :nothing
      JUST = :just

      class << self
        def pure(value)
          new(is: JUST, value: value)
        end
        alias_method :just, :pure

        def nothing
          new(is: NOTHING)
        end

        def to_maybe(value_or_nil)
          value_or_nil.nil? ? nothing : pure(value_or_nil)
        end
      end

      def fmap(&block)
        return dup if nothing? || !block
        self.class.just(yield(value))
      end

      def bind(&block)
        return dup if nothing? || !block
        yield value
      end

      def nothing?
        is == NOTHING
      end

      def just?
        is == JUST
      end

      def from_maybe
        return yield if nothing?
        value
      end

      def ==(other)
        to_obj == other.to_obj
      end

      def to_obj
        {is.to_s => value, :class => self.class.name}
      end

      private

      attr_reader :is, :value
      def initialize(is:, value: nil)
        @is = is
        @value = value
      end

      def dup
        self.class.new(is: is, value: value)
      end
    end
  end
end
