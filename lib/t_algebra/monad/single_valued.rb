require "fiber"
# @abstract
module TAlgebra
  module Monad
    module SingleValued
      module Static
        def chain(&block)
          receiver = augmented_receiver(block)
          fiber = Fiber.new { receiver.instance_exec(&block) }
          chain_recursive(fiber, [])
        end

        private

        def chain_recursive(fiber, current)
          val = fiber.resume current

          if fiber.alive?
            chain_bind(val.call) { |subsequent| chain_recursive(fiber, subsequent) }
          else
            val.is_a?(self.class) ? val : pure(val)
          end
        end
      end

      class << self
        def included(base)
          base.class_eval do
            include TAlgebra::Monad
          end
          base.extend(Static)
        end
      end
    end
  end
end
