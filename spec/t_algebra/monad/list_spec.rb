RSpec.describe TAlgebra::Monad::List do
  describe "constructors" do
    it ".pure" do
      l = pure(5)
      expect(l).to be_instance_of(described_class)

      l = pure(5, 6, 7)
      expect(l).to be_instance_of(described_class)
    end
  end

  describe "==" do
    it "lists equal" do
      expect(pure(5)).to eq(pure(5))
      expect(pure(5, 6)).to eq(pure(5, 6))
      expect(pure(5)).not_to eq(pure(5, 6))
      expect(pure(5, 6)).not_to eq(pure(6, 5))
    end
  end

  context "Functor" do
    describe "#fmap" do
      it "maps" do
        result = pure(5, 6, 7).fmap { |x| x + 3 }
        expect(result).to eq(pure(8, 9, 10))
      end
    end
  end

  context "Applicative" do
    describe ".lift_a2" do
      it "lifts on two lists" do
        l1 = pure(5, 6)
        l2 = pure("a", "b")

        result = described_class.lift_a2(l1, l2) do |element1, element2|
          {l1: element1, l2: element2}
        end

        expected_result = pure(
          {l1: 5, l2: "a"},
          {l1: 5, l2: "b"},
          {l1: 6, l2: "a"},
          {l1: 6, l2: "b"}
        )
        expect(result).to eq(expected_result)
      end
    end

    describe ".seq_a" do
      it "sequences on array of lists" do
        ls = [pure(5, 6), pure("a", "b")]

        expected_result = pure([5, "a"], [5, "b"], [6, "a"], [6, "b"])

        expect(described_class.seq_a(*ls)).to eq(expected_result)
      end

      it "sequences on hash of lists" do
        ls = {fst: pure(5, 6), snd: pure("a", "b")}

        expected_result = pure({fst: 5, snd: "a"}, {fst: 5, snd: "b"}, {fst: 6, snd: "a"}, {fst: 6, snd: "b"})

        expect(described_class.seq_a(**ls)).to eq(expected_result)
      end
    end
  end

  context "Monad" do
    describe "#bind" do
      it "binds like flatmap" do
        result = pure(5, 6).bind do |element|
          pure(element, element - 1, element)
        end

        expected_result = pure(5, 4, 5, 6, 5, 6)
        expect(result).to eq(expected_result)
      end
    end

    describe ".chain" do
      it "runs like flatmap" do
        result = described_class.chain do
          v1 = bound { pure(3, 5) }
          v2 = bound { pure(1, 2) }
          v1**v2
        end

        expect(result).to eq(pure(3, 9, 5, 25))
      end
    end
  end

  def pure(*l)
    described_class.pure(*l)
  end
end
