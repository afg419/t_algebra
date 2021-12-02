module TAlgebra
  module Monad
    class Parser < Either
      include TAlgebra::Monad

      def initialize(is:, value:, name: nil)
        super(is: is, value: value)
        @name = name
      end

      class << self
        def failure(msg, name = nil)
          left(msg).with_name(name)
        end

        def parse(val, name = nil)
          right(val).with_name(name)
        end

        def fetch(o, key)
          parser = parse(o.respond_to?(:[]) ? o[key] : o.send(key))
          parser.with_name(key).optional
        end

        def fetch!(o, key)
          parser = parse(o.respond_to?(:[]) ? o[key] : o.send(key))
          parser.with_name(key).required
        end
      end

      attr_reader :name
      def with_name(name)
        @name = name
        self
      end

      alias_method :valid?, :right?
      alias_method :failure?, :left?

      def fmap
        super.with_name(name)
      rescue => e
        self.class.failure("Unable to fmap: #{e}", name)
      end

      def bind
        super
      rescue => e
        self.class.failure("Unable to bind: #{e}", name)
      end

      def is_a?(*klasses)
        validate("Must be type #{klasses.join(", ")}") do |v|
          klasses.any? { |k| v.is_a?(k) }
        end
      end

      def validate(msg = "Invalid")
        n = name
        bind { |val| yield(val) ? parse(val, n) : failure(msg, n) }
      end

      def extract_parsed(&block)
        return yield("#{name}: #{value}") if left? && !name.nil?
        from_either(&block)
      end

      def required
        validate("Is required") { |v| !v.nil? }
      end

      def optional
        Optional.new(is: is, value: value, name: name)
      end

      class Optional < Parser
        def bind(&block)
          return dup if failure? || value.nil?

          required.bind(&block).optional
        end

        def fmap(&block)
          return dup if failure? || value.nil?

          required.fmap(&block).optional
        end

        def required
          Parser.new(is: is, value: value, name: name).required
        end
      end

      private

      def dup
        self.class.new(is: is, value: value, name: name)
      end
    end
  end
end
