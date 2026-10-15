module Mahjong
  module Config
    class RuleConfig
    DEFAULTS = {
      "game_type" => "hanchan",
      "initial_score" => 25000,
      "oka_origin" => 30000,
      "uma" => [20000, 10000, -10000, -20000],
      "aka_dora" => { "m" => 1, "p" => 1, "s" => 1 },
      "kuitan" => true,
      "atozuke" => true,
      "double_yakuman" => false,
      "kazoe_yakuman" => true,
      "kiriage_mangan" => false,
      "triple_ron_draw" => true,
      "double_ron" => true,
      "tobi" => true,
      "nishi_iri" => false,
      "nishi_iri_threshold" => 30000,
      "renpuu_jantou_fu" => 2,
      "minkan_dora_after_discard" => false
    }.freeze

    def initialize(config = {})
      normalized = (config || {}).each_with_object({}) do |(key, value), hash|
        hash[key.to_s] = value
      end
      @config = DEFAULTS.merge(normalized)
    end

    # 動的メソッドアクセス
    DEFAULTS.each_key do |key|
      define_method(key) { @config[key] }
      define_method("#{key}?") { !!@config[key] } if [true, false].include?(DEFAULTS[key])
    end

    def aka_dora_config
      @config["aka_dora"]
    end

    def uma_values
      @config["uma"]
    end

    def to_h
      @config.dup
    end

    def to_json(*args)
      JSON.generate(@config, *args)
    end
    end
  end
end
