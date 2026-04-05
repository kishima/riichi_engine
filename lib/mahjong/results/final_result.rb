module Mahjong
  module Results
    class FinalResult
      attr_reader :seat, :player_id, :name, :rank, :score, :adjusted_score, :point

      def initialize(**attrs)
        attrs.each { |k, v| instance_variable_set(:"@#{k}", v) }
      end
    end
  end
end
