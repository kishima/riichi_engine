require_relative "../../../spec_helper"

RSpec.describe Mahjong::Scoring::Judges::FuritenJudge do
  def build_state(hand_notations, kawa_notations = [])
    state = Mahjong::State::RoundState.new
    state.hands[0] = Mahjong::State::Hand.from_array(hand_notations)
    kawa = Mahjong::State::Kawa.new
    kawa_notations.each { |n| kawa.add(n) }
    state.kawas[0] = kawa
    state
  end

  describe ".judge" do
    context "テンパイしていない場合" do
      it "フリテンにならない" do
        state = build_state(%w[1m 3m 5m 7m 9m 1p 3p 5p 7p 9p 1z 3z 5z])
        result = described_class.judge(state: state, seat: 0)
        expect(result.furiten?).to be false
      end
    end

    context "通常フリテン" do
      it "自分の待ち牌が自分の捨て牌にある場合" do
        # 123m 456m 789m 12p 11z → 3p 待ち で、3p を既に捨てている
        hand   = %w[1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 1z 1z]
        kawa   = %w[3p]
        state  = build_state(hand, kawa)
        result = described_class.judge(state: state, seat: 0)
        expect(result.furiten?).to be true
        expect(result.type).to eq(:normal)
      end

      it "待ち牌が捨て牌にない場合はフリテンでない" do
        hand   = %w[1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 1z 1z]
        kawa   = %w[9p]
        state  = build_state(hand, kawa)
        result = described_class.judge(state: state, seat: 0)
        expect(result.furiten?).to be false
      end
    end

    context "同巡フリテン" do
      it "dojun_furiten_flags が true の場合" do
        hand   = %w[1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 1z 1z]
        state  = build_state(hand)
        state.instance_variable_set(:@dojun_furiten_flags, { 0 => true })
        def state.dojun_furiten_flags; @dojun_furiten_flags; end
        result = described_class.judge(state: state, seat: 0)
        expect(result.furiten?).to be true
        expect(result.type).to eq(:dojun)
      end
    end

    context "リーチ後フリテン" do
      it "リーチ中で riichi_furiten_flags が true の場合" do
        hand   = %w[1m 2m 3m 4m 5m 6m 7m 8m 9m 1p 2p 1z 1z]
        state  = build_state(hand)
        state.riichi_flags[0] = true
        state.instance_variable_set(:@riichi_furiten_flags, { 0 => true })
        def state.riichi_furiten_flags; @riichi_furiten_flags; end
        result = described_class.judge(state: state, seat: 0)
        expect(result.furiten?).to be true
        expect(result.type).to eq(:riichi)
      end
    end
  end
end
