module TAlgebra
  module Monad
    class Maybe
      include TAlgebra::Monad::SingleValued

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

        # def run_bind(ma, &block)
        #   # raise "Yield blocks must return instances of #{self}. Got #{ma.class}" unless [Parser, Parser::Optional].include?(ma.class)
        #
        #   ma.bind(&block)
        # end
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

      def from_maybe!
        from_maybe { |e| raise UnsafeError.new("#from_maybe! exception. #{e}") }
      end

      def from_maybe
        raise UseError.new("#from_maybe called without block") unless block_given?
        return yield if nothing?
        value
      end

      def fetch(key)
        bind do |o|
          self.class.to_maybe(
            o.respond_to?(:[]) ? o[key] : o.send(key)
          )
        end
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
