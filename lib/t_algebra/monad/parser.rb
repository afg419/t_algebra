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
          new(is: Either::LEFT, value: msg, name: name)
        end

        def parse(val, name = nil)
          new(is: Either::RIGHT, value: val, name: name)
        end

        def fetch(o, key)
          parse(o).fetch(key)
        end

        def fetch!(o, key)
          parse(o).fetch!(key)
        end

        def run_bind(ma, &block)
          raise "Yield blocks must return instances of #{self}. Got #{ma.class}" unless [Parser, Parser::Optional].include?(ma.class)

          ma.as_parser.bind(&block)
        end
      end

      alias_method :valid?, :right?
      alias_method :failure?, :left?

      attr_reader :name
      def with_name(name)
        @name = name
        self
      end

      def fetch(key)
        with_name(key).fmap { |o| o.respond_to?(:[]) ? o[key] : o.send(key) }.optional
      end

      def fetch!(key)
        with_name(key).fmap { |o| o.respond_to?(:[]) ? o[key] : o.send(key) }.required
      end

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
        bind { |val| yield(val) ? Parser.parse(val, n) : Parser.failure(msg, n) }
      end

      def extract_parsed(&block)
        return yield("#{name}: #{value}") if left? && !name.nil?
        from_either(&block)
      end

      def extract_parsed!
        extract_parsed { |e| raise UnsafeError.new("#extract_parsed! exception. #{e}") }
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

      def as_parser
        instance_of?(Parser::Optional) ? Parser.new(is: is, value: value, name: name) : self
      end

      private

      def dup
        self.class.new(is: is, value: value, name: name)
      end
    end
  end
end
