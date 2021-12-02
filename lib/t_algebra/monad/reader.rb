module TAlgebra
  module Monad
    class Reader
      include TAlgebra::Monad

      class << self
        def pure(a)
          new { a }
        end

        def ask
          new { |r| r }
        end
      end

      def fmap(&a_to_b)
        Reader.new(&(r_to_a >> a_to_b))
      end

      def bind(&a_to_mb)
        Reader.new do |r|
          (r_to_a >> a_to_mb).call(r).run_reader(r)
        end
      end

      def run_reader(r)
        r_to_a.call(r)
      end

      private

      attr_reader :r_to_a
      def initialize(&r_to_a)
        @r_to_a = r_to_a
      end

      def dup
        self.class.new(&r_to_a)
      end
    end
  end
end
