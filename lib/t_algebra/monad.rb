require "fiber"
# @abstract
module TAlgebra
  module Monad
    def bind(&block)
      raise "Implement #bind in extending class"
    end

    module Static
      def chain(&block)
        receiver = augmented_receiver(block)
        fiber_initializer = -> { Fiber.new { receiver.instance_exec(&block) } }
        chain_recursive(fiber_initializer, [])
      end
      alias_method :run, :chain

      def bound(&block)
        Fiber.yield(block)
      end
      alias_method :_pick, :bound

      def augmented_receiver(block)
        block_self = block.binding.receiver

        self_class = self
        block_self.define_singleton_method(:method_missing) do |m, *args, &block|
          self_class.send(m, *args, &block)
        end

        block_self
      end

      def chain_bind(ma, &block)
        raise "Yield blocks must return instances of #{self}" unless ma.instance_of?(self)
        ma.bind(&block)
      end

      def lift_a2(ma, mb)
        ma.bind do |a|
          mb.bind do |b|
            pure(yield(a, b))
          end
        end
      end

      private

      def chain_recursive(fiber_initializer, historical_values)
        fiber = fiber_initializer.call

        val = fiber.resume
        historical_values.each do |h|
          val = fiber.resume h
        end

        if fiber.alive?
          chain_bind(val.call) { |a| chain_recursive(fiber_initializer, historical_values + [a]) }
        else
          val.is_a?(self.class) ? val : pure(val)
        end
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
