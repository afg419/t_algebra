module TAlgebra
  module Monad
    class List
      include TAlgebra::Monad

      class << self
        alias_method :pure, :new
      end

      def fmap(&block)
        self.class.pure(
          *values.map { |l| yield(l) }
        )
      end

      def bind(&block)
        self.class.pure(
          *values.reduce([]) do |acc, l|
            acc.concat(block.call(l).send(:values))
          end
        )
      end

      def from_list
        values
      end

      def ==(other)
        from_list == other.from_list
      end

      private

      attr_reader :values
      def initialize(*values)
        @values = values || []
      end
    end
  end
end
