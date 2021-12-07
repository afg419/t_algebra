class FetchableExample
  attr_reader :key
  def initialize
    @key = "value"
  end
end

RSpec.describe TAlgebra::Monad::Parser do
  describe "constructors" do
    it ".parse" do
      m = parse(5)
      expect(m).to be_instance_of(described_class)
      expect(m.failure?).to be(false)
      expect(m.valid?).to be(true)
    end

    it ".failure" do
      m = failure("err")
      expect(m).to be_instance_of(described_class)
      expect(m.failure?).to be(true)
      expect(m.valid?).to be(false)
    end
  end

  describe "==" do
    it "parse == parse" do
      e1 = parse(5)
      e2 = parse(5)
      expect(e1).to eq(e2)
    end

    it "parse != parse" do
      e1 = parse(5)
      e2 = parse(6)
      expect(e1).not_to eq(e2)
    end

    it "failure != parse" do
      e1 = failure(5)
      e2 = parse(5)
      expect(e1).not_to eq(e2)
    end

    it "failure == failure" do
      e1 = failure(5)
      e2 = failure(5)
      expect(e1).to eq(e2)
    end

    it "failure != failure" do
      e1 = failure(5)
      e2 = failure(6)
      expect(e1).not_to eq(e2)
    end
  end

  describe "#extract_parsed" do
    it "extracts from right" do
      result = parse(6).extract_parsed { |e| raise e }
      expect(result).to eq(6)
    end

    it "calls block on failure" do
      expect {
        failure("err").extract_parsed { |e| raise e }
      }.to raise_error("err")
    end
  end

  describe ".fetch" do
    context "required (fetch!)" do
      it "fetches required value from hash" do
        expect(fetch!({key: "value"}, :key)).to eq(parse("value"))
      end

      it "fetches required value from array" do
        expect(fetch!(["value"], 0)).to eq(parse("value"))
      end

      it "fetches required value from object" do
        expect(fetch!(FetchableExample.new, :key)).to eq(parse("value"))
      end
    end

    context "optional (fetch)" do
      it "fetches optional value from hash" do
        expect(fetch({key: "value"}, :key)).to eq(parse("value").optional)
      end

      it "fetches optional value from array" do
        expect(fetch(["value"], 0)).to eq(parse("value").optional)
      end

      it "fetches optional value from object" do
        expect(fetch(FetchableExample.new, :key)).to eq(parse("value").optional)
      end
    end
  end

  context "Parser::Optional" do
    describe "#required" do
      it "converts to parser on required" do
        e = parse(5).optional
        expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        expect(e.required).to eq(parse(5))
        expect(e.required).to be_instance_of(TAlgebra::Monad::Parser)
      end

      it "fails to parser on required if nil" do
        e = parse(nil).optional
        expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        expect(e.required.failure?).to eq(true)
        expect(e.required).to be_instance_of(TAlgebra::Monad::Parser)
      end

      it "fails to parser on required if failure" do
        e = failure("err").optional
        expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        expect(e.required.failure?).to eq(true)
        expect(e.required).to be_instance_of(TAlgebra::Monad::Parser)
      end

      describe "#fetch" do
        it "does &." do
          ex = parse({a: {b: {c: 5}}})
          result1 = ex.fetch(:a).fetch(:b).fetch(:c)
          expect(result1.extract_parsed!).to eq(5)

          result2 = ex.fetch(:a).fetch(:non_existant).fetch(:c)
          expect(result2.extract_parsed!).to eq(nil)
        end

        it "does ." do
          ex = parse({a: {b: {c: 5}}})
          result1 = ex.fetch!(:a).fetch!(:b).fetch!(:c)
          expect(result1.extract_parsed!).to eq(5)

          result2 = ex.fetch!(:a).fetch!(:non_existant).fetch!(:c)
          expect { result2.extract_parsed! }.to raise_error(TAlgebra::Monad::UnsafeError)
        end
      end
    end

    context "Functor" do
      describe "#fmap" do
        it "maps when parsed present" do
          e = parse(5).optional.fmap { |x| x + 1 }
          expect(e).to eq(parse(6).optional)
          expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        end

        it "doesnt map when parsed absent" do
          e = parse(nil).optional.fmap { |x| x + 1 }
          expect(e).to eq(parse(nil).optional)
          expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        end

        it "doesnt map on error" do
          e = parse(5).optional.fmap { |_| raise "Block Exploded" }
          expect(e.failure?).to eq(true)
          expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        end

        it "doesnt map when failure" do
          e = failure("err").optional.fmap { |x| x + 1 }
          expect(e).to eq(failure("err").optional)
          expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        end
      end

      describe "#bind" do
        it "binds when parsed present" do
          e = parse(5).optional.bind { |x| parse(x + 1) }
          expect(e).to eq(parse(6).optional)
          expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        end

        it "bind block can return Parser or Parser::Optional" do
          e = parse(5).optional.bind { |x| parse(x + 1).optional }
          expect(e).to eq(parse(6).optional)
          expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        end

        it "doesnt bind when parsed absent" do
          e = parse(nil).optional.bind { |x| parse(x + 1) }
          expect(e.failure?).to eq(false)
          expect(e).to eq(parse(nil).optional)
          expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        end

        it "doesnt bind on error" do
          e = parse(5).optional.bind { |_| raise "Block Exploded" }
          expect(e.failure?).to eq(true)
          expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        end

        it "doesnt bind when failure" do
          e = failure("err").optional.bind { |x| parse(x + 1) }
          expect(e).to eq(failure("err").optional)
          expect(e).to be_instance_of(TAlgebra::Monad::Parser::Optional)
        end
      end
    end
  end

  context "Functor" do
    describe "#fmap" do
      it "maps when parse" do
        e = parse(5).fmap { |x| x + 1 }
        expect(e).to eq(parse(6))
      end

      it "doesnt map on error" do
        e = parse(5).fmap { |_| raise "Block Exploded" }
        expect(e.failure?).to eq(true)
      end

      it "doesnt map when failure" do
        e = failure("err").fmap { |x| x + 1 }
        expect(e).to eq(failure("err"))
      end
    end
  end

  context "Applicative" do
    describe ".lift_a2" do
      it "lifts on two rights" do
        e1 = parse(5)
        e2 = parse(6)
        expect(described_class.lift_a2(e1, e2, &:+)).to eq(parse(11))
      end

      it "doesnt lift on a failure" do
        e1 = parse(5)
        e2 = failure(6)
        expect(described_class.lift_a2(e1, e2, &:+)).to eq(failure(6))

        e3 = failure(5)
        e4 = parse(6)
        expect(described_class.lift_a2(e3, e4, &:+)).to eq(failure(5))

        e5 = failure(5)
        e6 = failure(6)
        expect(described_class.lift_a2(e5, e6, &:+)).to eq(failure(5))
      end
    end

    describe ".seq_a" do
      it "sequences on all rights" do
        es1 = [parse(5), parse(6)]
        expect(described_class.seq_a(*es1)).to eq(parse([5, 6]))

        es2 = {fst: parse(5), snd: parse(6)}
        expect(described_class.seq_a(**es2)).to eq(parse({fst: 5, snd: 6}))
      end

      it "doesnt sequence on a failure" do
        es1 = [failure("err"), parse(6)]
        expect(described_class.seq_a(*es1)).to eq(failure("err"))

        es2 = {fst: parse(5), snd: failure("err")}
        expect(described_class.seq_a(**es2)).to eq(failure("err"))
      end
    end
  end

  context "Monad" do
    describe "#bind" do
      it "binds when parse" do
        e = parse(5).bind { |x| parse(x + 1) }
        expect(e).to eq(parse(6))
      end

      it "doesnt bind on error" do
        e = parse(5).bind { |_| raise "Block Exploded" }
        expect(e.failure?).to eq(true)
      end

      it "doesnt bind when failure" do
        e = failure("err").bind { |x| parse(x + 1) }
        expect(e).to eq(failure("err"))
      end
    end

    describe ".run" do
      it "runs on rights" do
        result = described_class.run do |y|
          v1 = y.yield { parse(5) }
          v2 = y.yield { parse(v1 + 10) }
          v1 + v2
        end

        expect(result).to eq(parse(20))
      end

      it "short circuits on lefts" do
        result = described_class.run do |y|
          v1 = y.yield { parse(5) }
          v2 = y.yield { failure("err") }
          v1 + v2
        end

        expect(result).to eq(failure("err"))
      end
    end
  end

  describe "#is_a?" do
    it "is_a? on right" do
      expect(parse(5).is_a?(Numeric).valid?).to be(true)
      expect(parse(5).is_a?(String).valid?).to be(false)
      expect(parse(5).is_a?(String, Numeric).valid?).to be(true)
      expect(parse(5).is_a?(String, Time).valid?).to be(false)
    end
    it "is_a? on right" do
      expect(failure(5).is_a?(Numeric).valid?).to be(false)
    end
  end

  def failure(e)
    described_class.failure(e)
  end

  def parse(x)
    described_class.parse(x)
  end

  def fetch(o, k)
    described_class.fetch(o, k)
  end

  def fetch!(o, k)
    described_class.fetch!(o, k)
  end
end
