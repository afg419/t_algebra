require "dry/monads"
require "benchmark/ips"

class DryMaybe
  # This will include Do::All by default
  include Dry::Monads[:maybe, :do]

  def justs
    a = yield Dry::Monads::Maybe(3)
    b = yield Dry::Monads::Maybe(4)
    c = yield Dry::Monads::Maybe(5)
    a + b + c
  end

  def nothings
    a = yield Dry::Monads::None.new
    b = yield Dry::Monads::Maybe(4)
    c = yield Dry::Monads::Maybe(5)
    a + b + c
  end
end

class TAlgebraMaybe
  def justs
    TAlgebra::Monad::Maybe.chain do
      a = bound { just(3) }
      b = bound { just(4) }
      c = bound { just(5) }
      a + b + c
    end
  end

  def nothings
    TAlgebra::Monad::Maybe.chain do
      a = bound { just(3) }
      b = bound { nothing }
      c = bound { just(5) }
      a + b + c
    end.from_maybe { Dry::Monads::None.new }
  end
end

RSpec.describe "object count" do
  context "#justs" do
    it "matches" do
      expect(DryMaybe.new.justs).to eq(TAlgebraMaybe.new.justs.from_maybe!)
    end

    it "compares" do
      dry = DryMaybe.new
      t_alg = TAlgebraMaybe.new

      Benchmark.ips do |x|
        # Typical mode, runs the block as many times as it can
        x.report("t_algebra") { t_alg.justs }
        x.report("dry") { dry.justs }
        # Compare the iterations per second of the various reports!
        x.compare!
      end
    end
  end

  context "#nothings" do
    it "matches" do
      expect(DryMaybe.new.nothings).to eq(TAlgebraMaybe.new.nothings)
    end

    it "compares" do
      dry = DryMaybe.new
      t_alg = TAlgebraMaybe.new

      Benchmark.ips do |x|
        # Typical mode, runs the block as many times as it can
        x.report("t_algebra") { t_alg.nothings }
        x.report("dry") { dry.nothings }
        # Compare the iterations per second of the various reports!
        x.compare!
      end
    end
  end
end
