module TAlgebra
  module Monad
    class Either
      include TAlgebra::Monad

      LEFT = :left
      RIGHT = :right

      class << self
        def pure(value)
          new(is: RIGHT, value: value)
        end
        alias_method :right, :pure

        def left(err)
          new(is: LEFT, value: err)
        end
      end

      def fmap(&block)
        return dup if left? || !block

        self.class.pure(yield(value))
      end

      def bind(&block)
        return dup if left? || !block

        self.class.instance_exec(value, &block)
      end

      def left?
        is == LEFT
      end

      def right?
        is == RIGHT
      end

      def from_either
        return yield(value) if left?
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

      def initialize(is:, value:)
        @is = is
        @value = value
      end

      def dup
        self.class.new(is: is, value: value)
      end
    end
  end
end
