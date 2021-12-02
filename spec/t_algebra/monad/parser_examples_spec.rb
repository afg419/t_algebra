require "Date"

class HallOfFamer
  attr_reader :first, :last, :full, :born, :team
  def initialize(first:, last:, full:, born:, team:)
    @first, @last, @full, @born, @team = first, last, full, born, team
  end
end

RSpec.describe TAlgebra::Monad::Parser do
  let(:subject) { described_class.parse(api_result) }

  context "run syntax" do
    it "parses an API result to a HallOfFamer using run" do
      api_result = {
        firstName: "george",
        lastName: "ruth",
        suffix: "jr",
        knownAs: "Babe Ruth",
        fullName: "George Herman Ruth",
        born: "1895-2-6",
        died: "1948-8-16",
        livedTo: 53,
        team: {
          city: "New York",
          name: "yankees"
        }
      }

      hall_of_famer = TAlgebra::Monad::Parser.run do |y|
        # validate presence with `.fetch!` and type with `#is_a?``
        first = y.yield { fetch!(api_result, :firstName).is_a?(String) }
        last = y.yield { fetch!(api_result, :lastName).is_a?(String) }

        # allow nil with `.fetch`. Transform fetched result with `#fmap` and apply custom validators with `#validate`
        suffix = y.yield do
          fetch(api_result, :suffix)
            .is_a?(String)
            .fmap { |x| x.downcase }
            .validate("Is valid suffix") { |x| (%w[jr sr i ii iii].include? x) }
            .fmap { |x| x.capitalize }
        end

        # previous parses like first + last + suffix can be used in subsequent parse definitions
        full = y.yield do
          fetch!(api_result, :fullName)
            .is_a?(String)
            .validate("Full name consistent") { |x| x.include?(first.capitalize) && x.include?(last.capitalize) }
            .fmap { |full_name| suffix.nil? ? full_name : "#{full_name}, #{suffix}" }
        end

        # This will fmap the born date string to a Date object, or the parse will fail
        born = y.yield { fetch!(api_result, :born).fmap { |x| Date.parse(x) } }
        died = y.yield { fetch(api_result, :died).fmap { |x| Date.parse(x) } }

        # We may want to validate part of the structure without needing its result
        y.yield do
          fetch(api_result, :livedTo)
            .is_a?(Numeric)
            .validate("Age is correct") { |x| died.nil? ? true : (died.year - born.year == x) }
        end

        team_hash = y.yield { fetch!(api_result, :team).is_a?(Hash) }
        team = y.yield do
          fetch!(team_hash, :name)
            .is_a?(String)
            .validate("Teamname known") { |t| true }
            .fmap(&:capitalize)
        end

        HallOfFamer.new(first: first, last: last, full: full, born: born, team: team)
      end.extract_parsed { |errors| raise errors }

      expect(hall_of_famer.first).to eq("george")
      expect(hall_of_famer.last).to eq("ruth")
      expect(hall_of_famer.full).to eq("George Herman Ruth, Jr")
      expect(hall_of_famer.born).to eq(Date.parse("1895/2/6"))
      expect(hall_of_famer.team).to eq("Yankees")
    end
  end
end
