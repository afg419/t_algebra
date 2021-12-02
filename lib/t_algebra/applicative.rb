# @abstract
module TAlgebra
  module Applicative
    module Static
      def pure(_)
        raise "Implement .pure in extending class"
      end

      def lift_a2(_fa, _fb, &_block)
        raise "Implement .lift_a2 in extending class"
      end

      def seq_a(*array_of_parsers, **hash_of_parsers)
        return sequence_array(array_of_parsers) unless array_of_parsers.empty?

        sequence_hash(hash_of_parsers) unless hash_of_parsers.empty?
      end

      # @param [Array<Applicative>] fbs
      # @return [Applicative<Array>]
      def sequence_array(fbs)
        return pure([]) if fbs.empty?

        fbs.reduce(pure([])) do |prev, fb|
          lift_a2(prev, fb) do |p, b|
            p + [b]
          end
        end
      end

      # @param [Hash<Any, Applicative>] fbs
      # @return [Applicative<Hash>]
      def sequence_hash(fbs)
        return pure({}) if fbs.empty?

        fbs.reduce(pure({})) do |prev, (k, fb)|
          lift_a2(prev, fb) do |p, b|
            p.merge(k => b)
          end
        end
      end
    end

    class << self
      def included(base)
        base.class_eval do
          include TAlgebra::Functor
        end
        base.extend(Static)
      end
    end
  end
end
