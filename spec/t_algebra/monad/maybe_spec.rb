RSpec.describe TAlgebra::Monad::Maybe do
  describe "constructors" do
    it ".just" do
      m = just(5)
      expect(m).to be_instance_of(described_class)
      expect(m.nothing?).to be(false)
      expect(m.just?).to be(true)
    end

    it ".nothing" do
      m = nothing
      expect(m).to be_instance_of(described_class)
      expect(m.nothing?).to be(true)
      expect(m.just?).to be(false)
    end

    it ".to_maybe" do
      m1 = described_class.to_maybe(nil)
      expect(m1).to be_instance_of(described_class)
      expect(m1.nothing?).to be(true)
      expect(m1.just?).to be(false)

      m2 = described_class.to_maybe(5)
      expect(m2).to be_instance_of(described_class)
      expect(m2.nothing?).to be(false)
      expect(m2.just?).to be(true)
    end
  end

  describe "==" do
    it "nothing == nothing" do
      m1 = nothing
      m2 = nothing
      expect(m1).to eq(m2)
    end

    it "nothing != just" do
      m1 = nothing
      m2 = just(5)
      expect(m1).not_to eq(m2)
    end

    it "just == just" do
      m1 = just(5)
      m2 = just(5)
      expect(m1).to eq(m2)
    end

    it "just != just" do
      m1 = just(5)
      m2 = just(6)
      expect(m1).not_to eq(m2)
    end
  end

  context "#fetch" do
    it "can do &." do
      val = just({a: {b: {c: 1}}}).fetch(:a).fetch(:b).fetch(:c).from_maybe!
      expect(val).to eq(1)

      val = just({a: {b: {c: 1}}}).fetch(:a).fetch(:non_existant).fetch(:c).from_maybe { nil }
      expect(val).to eq(nil)
    end
  end

  context "Functor" do
    describe "#fmap" do
      it "maps when just" do
        m = just(5).fmap { |x| x + 1 }
        expect(m).to eq(just(6))
      end

      it "doesnt map when nothing" do
        m = nothing.fmap { |x| x + 1 }
        expect(m).to eq(nothing)
      end
    end
  end

  context "Applicative" do
    describe ".lift_a2" do
      it "lifts on two justs" do
        m1 = just(5)
        m2 = just(6)
        expect(described_class.lift_a2(m1, m2, &:+)).to eq(just(11))
      end

      it "doesnt lift on a nothing" do
        m1 = just(5)
        m2 = nothing
        expect(described_class.lift_a2(m1, m2, &:+)).to eq(nothing)

        m3 = nothing
        m4 = just(6)
        expect(described_class.lift_a2(m3, m4, &:+)).to eq(nothing)

        m5 = nothing
        m6 = nothing
        expect(described_class.lift_a2(m5, m6, &:+)).to eq(nothing)
      end
    end

    describe ".seq_a" do
      it "sequences on all justs" do
        ms1 = [just(5), just(6)]
        expect(described_class.seq_a(*ms1)).to eq(just([5, 6]))

        ms2 = {fst: just(5), snd: just(6)}
        expect(described_class.seq_a(**ms2)).to eq(just({fst: 5, snd: 6}))
      end

      it "doesnt sequence on a nothing" do
        ms1 = [nothing, just(6)]
        expect(described_class.seq_a(*ms1)).to eq(nothing)

        ms2 = {fst: just(5), snd: nothing}
        expect(described_class.seq_a(**ms2)).to eq(nothing)
      end
    end
  end

  context "Monad" do
    describe "#bind" do
      it "binds when just" do
        m = just(5).bind { |x| just(x + 1) }
        expect(m).to eq(just(6))
      end

      it "doesnt bind when nothing" do
        m = nothing.bind { |x| just(x + 1) }
        expect(m).to eq(nothing)
      end
    end

    describe ".run" do
      it "runs on just" do
        result = described_class.run do |y|
          v1 = y.yield { just(5) }
          v2 = y.yield { just(v1 + 10) }
          v1 + v2
        end

        expect(result).to eq(just(20))
      end

      it "short circuits on nothing" do
        result = described_class.run do |y|
          v1 = y.yield { just(5) }
          v2 = y.yield { nothing }
          v1 + v2
        end

        expect(result).to eq(nothing)
      end
    end
  end

  def nothing
    described_class.nothing
  end

  def just(x)
    described_class.just(x)
  end
end
