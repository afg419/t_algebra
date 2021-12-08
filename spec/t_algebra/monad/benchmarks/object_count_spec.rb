RSpec.describe "object count" do
  it "can clean intermediary objects from memory (valid)" do
    result, initial_objects, final_objects = with_object_count do
      parser = TAlgebra::Monad::Parser.parse(infinite_hash)

      100000.times do
        parser = parser
          .fetch!(:some_mandatory_key)
          .fetch(:some_optional_key)
      end

      parser
    end

    expect(final_objects).to be <= initial_objects + 2 # 1 extra is the parser object referenced below... the other not sure
    expect(result.extract_parsed!).to eq({})
  end

  it "can clean intermediary objects from memory (invalid)" do
    result, initial_objects, final_objects = with_object_count do
      parser = TAlgebra::Monad::Parser.parse({})

      100000.times do
        parser = parser
          .fetch!(:some_mandatory_key)
          .fetch(:some_optional_key)
      end

      parser
    end

    expect(final_objects).to be <= initial_objects + 2 # 1 extra is the parser object referenced below... the other not sure
    expect { result.extract_parsed! }.to raise_error(TAlgebra::UnsafeError)
  end

  def infinite_hash
    Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
  end

  def with_object_count
    GC.start
    initial_objects = {}
    final_objects = {}

    ObjectSpace.count_objects(initial_objects)

    result = yield

    GC.start
    ObjectSpace.count_objects(final_objects)

    [result, initial_objects[:T_OBJECT], final_objects[:T_OBJECT]]
  end
end
