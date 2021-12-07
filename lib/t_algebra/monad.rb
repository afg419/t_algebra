# @abstract
module TAlgebra
  module Monad
    def bind(&block)
      raise "Implement #bind in extending class"
    end

    module Static
      class LazyYielder
        def initialize(yielder)
          @yielder = yielder
        end

        def yield(&block)
          @yielder.yield(block)
        end
      end

      def run(&block)
        e = Enumerator.new { |y| instance_exec(LazyYielder.new(y), &block) }
        run_recursive(e, [])
      end

      def run_bind(ma, &block)
        raise "Yield blocks must return instances of #{self}" unless ma.instance_of?(self)
        ma.bind(&block)
      end

      def lift_a2(ma, mb, &block)
        ma.bind do |a|
          mb.bind do |b|
            pure(block.call(a, b))
          end
        end
      end

      private

      def run_recursive(enum, historical_values)
        enum.rewind

        historical_values.each do |h|
          enum.next
          enum.feed(h)
        end

        if is_complete(enum)
          val = value(enum)
          val.is_a?(self.class) ? val : pure(val)
        else
          run_bind(enum.next.call) do |a|
            run_recursive(enum, historical_values + [a])
          end
        end
      end

      def is_complete(enumerator)
        enumerator.peek
        false
      rescue StopIteration
        true
      end

      def value(enumerator)
        enumerator.peek
      rescue StopIteration
        $!.result
      end
    end

    class << self
      def included(base)
        base.class_eval do
          include TAlgebra::Applicative
        end
        base.extend(Static)
      end
    end
  end
end
