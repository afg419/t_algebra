RSpec.describe TAlgebra::Monad::Either do
  describe "constructors" do
    it ".right" do
      m = right(5)
      expect(m).to be_instance_of(described_class)
      expect(m.left?).to be(false)
      expect(m.right?).to be(true)
    end

    it ".left" do
      m = left("err")
      expect(m).to be_instance_of(described_class)
      expect(m.left?).to be(true)
      expect(m.right?).to be(false)
    end
  end

  describe "==" do
    it "right == right" do
      e1 = right(5)
      e2 = right(5)
      expect(e1).to eq(e2)
    end

    it "right != right" do
      e1 = right(5)
      e2 = right(6)
      expect(e1).not_to eq(e2)
    end

    it "left != right" do
      e1 = left(5)
      e2 = right(5)
      expect(e1).not_to eq(e2)
    end

    it "left == left" do
      e1 = left(5)
      e2 = left(5)
      expect(e1).to eq(e2)
    end

    it "left != left" do
      e1 = left(5)
      e2 = left(6)
      expect(e1).not_to eq(e2)
    end
  end

  describe "#from_either" do
    it "extracts from right" do
      result = right(6).from_either { |e| raise e }
      expect(result).to eq(6)
    end

    it "calls block on left" do
      expect {
        left("err").from_either { |e| raise e }
      }.to raise_error("err")
    end
  end

  context "Functor" do
    describe "#fmap" do
      it "maps when right" do
        e = right(5).fmap { |x| x + 1 }
        expect(e).to eq(right(6))
      end

      it "doesnt map when left" do
        e = left("err").fmap { |x| x + 1 }
        expect(e).to eq(left("err"))
      end
    end
  end

  context "Applicative" do
    describe ".lift_a2" do
      it "lifts on two rights" do
        e1 = right(5)
        e2 = right(6)
        expect(described_class.lift_a2(e1, e2, &:+)).to eq(right(11))
      end

      it "doesnt lift on a left" do
        e1 = right(5)
        e2 = left(6)
        expect(described_class.lift_a2(e1, e2, &:+)).to eq(left(6))

        e3 = left(5)
        e4 = right(6)
        expect(described_class.lift_a2(e3, e4, &:+)).to eq(left(5))

        e5 = left(5)
        e6 = left(6)
        expect(described_class.lift_a2(e5, e6, &:+)).to eq(left(5))
      end
    end

    describe ".seq_a" do
      it "sequences on all rights" do
        es1 = [right(5), right(6)]
        expect(described_class.seq_a(*es1)).to eq(right([5, 6]))

        es2 = {fst: right(5), snd: right(6)}
        expect(described_class.seq_a(**es2)).to eq(right({fst: 5, snd: 6}))
      end

      it "doesnt sequence on a left" do
        es1 = [left("err"), right(6)]
        expect(described_class.seq_a(*es1)).to eq(left("err"))

        es2 = {fst: right(5), snd: left("err")}
        expect(described_class.seq_a(**es2)).to eq(left("err"))
      end
    end
  end

  context "Monad" do
    describe "#bind" do
      it "binds when right" do
        e = right(5).bind { |x| right(x + 1) }
        expect(e).to eq(right(6))
      end

      it "doesnt bind when left" do
        e = left("err").bind { |x| right(x + 1) }
        expect(e).to eq(left("err"))
      end
    end

    describe ".run" do
      it "runs on rights" do
        result = described_class.run do |y|
          v1 = y.yield { right(5) }
          v2 = y.yield { right(v1 + 10) }
          v1 + v2
        end

        expect(result).to eq(right(20))
      end

      it "short circuits on lefts" do
        result = described_class.run do |y|
          v1 = y.yield { right(5) }
          v2 = y.yield { left("err") }
          v1 + v2
        end

        expect(result).to eq(left("err"))
      end
    end
  end

  def left(e)
    described_class.left(e)
  end

  def right(x)
    described_class.right(x)
  end
end
