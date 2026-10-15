"""Evaluate winning hands with the Python `mahjong` package (PyPI).

Reads a JSON array of cases on stdin (see python_mahjong_cases.rb) and writes a
JSON array of results on stdout, in the same order. Used only by the
comparison spec; not part of the gem.
"""
import json
import sys

from mahjong.constants import EAST, SOUTH, WEST, NORTH
from mahjong.hand_calculating.hand import HandCalculator
from mahjong.hand_calculating.hand_config import HandConfig, HandConstants, OptionalRules
from mahjong.meld import Meld

WINDS = {"ton": EAST, "nan": SOUTH, "sha": WEST, "pei": NORTH}
SUIT_BASE = {"m": 0, "p": 9, "s": 18, "z": 27}
RED_136 = {"m": 16, "p": 52, "s": 88}

# yaku_id of the Python package -> yaku name of riichi_engine
YAKU_NAMES = {
    0: "menzen_tsumo", 1: "riichi", 3: "ippatsu", 4: "chankan", 5: "rinshan_kaihou",
    6: "haitei", 7: "houtei", 8: "double_riichi", 12: "pinfu", 13: "tanyao", 14: "iipeiko",
    15: "yakuhai_haku", 16: "yakuhai_hatsu", 17: "yakuhai_chun",
    18: "yakuhai_jikaze", 19: "yakuhai_jikaze", 20: "yakuhai_jikaze", 21: "yakuhai_jikaze",
    22: "yakuhai_bakaze", 23: "yakuhai_bakaze", 24: "yakuhai_bakaze", 25: "yakuhai_bakaze",
    26: "sanshoku_doujun", 27: "ikkitsuukan", 28: "chanta", 29: "honroutou", 30: "toitoihou",
    31: "san_ankou", 32: "san_kantsu", 33: "sanshoku_doukou", 34: "chiitoitsu",
    35: "shousangen", 36: "honitsu", 37: "junchan", 38: "ryanpeiko", 39: "chinitsu",
    100: "kokushi_musou", 112: "kokushi_musou", 101: "chuuren_poutou", 114: "chuuren_poutou",
    102: "suuankou", 113: "suuankou", 103: "daisangen", 104: "shousuushii", 111: "daisuushii",
    105: "ryuuiisou", 106: "suukantsu", 107: "tsuuiisou", 108: "chinroutou",
    115: "tenhou", 116: "chiihou", 120: "dora", 121: "akadora", 122: "uradora",
}


class Allocator:
    """Gives each tile of a case its own 136 index (the red five its fixed one)."""

    def __init__(self):
        self.used = set()

    def take(self, notation):
        number, suit = int(notation[0]), notation[1]
        if number == 0:
            index = RED_136[suit]
            if index in self.used:
                raise ValueError("two red fives of " + suit)
            self.used.add(index)
            return index
        base = (SUIT_BASE[suit] + number - 1) * 4
        for index in range(base, base + 4):
            if index in self.used or (number == 5 and suit != "z" and index == RED_136[suit]):
                continue
            self.used.add(index)
            return index
        raise ValueError("more than four of " + notation)


MELD_TYPES = {"chi": Meld.CHI, "pon": Meld.PON, "daiminkan": Meld.KAN, "kakan": Meld.SHOUMINKAN, "ankan": Meld.KAN}


def evaluate(case):
    alloc = Allocator()
    concealed = [alloc.take(t) for t in case["concealed"]]
    win_tile = None
    if case["tsumo"]:
        win_tile = concealed[case["concealed"].index(case["win"])]
    else:
        win_tile = alloc.take(case["win"])
        concealed.append(win_tile)
    melds = []
    meld_tiles = []
    for m in case["melds"]:
        tiles = [alloc.take(t) for t in m["tiles"]]
        meld_tiles.extend(tiles)
        melds.append(Meld(meld_type=MELD_TYPES[m["type"]], tiles=tiles, opened=m["type"] != "ankan"))
    dora = [alloc.take(t) for t in case["dora_hyouji"]]
    ura = [alloc.take(t) for t in case["uradora_hyouji"]]
    options = OptionalRules(
        has_open_tanyao=True, has_aka_dora=True, has_double_yakuman=False,
        kazoe_limit=HandConstants.KAZOE_LIMITED, kiriage=False,
        fu_for_open_pinfu=True, fu_for_pinfu_tsumo=False,
    )
    config = HandConfig(
        is_tsumo=case["tsumo"], is_riichi=case["riichi"], is_ippatsu=case["ippatsu"],
        is_rinshan=case["rinshan"], is_chankan=case["chankan"], is_haitei=case["haitei"],
        is_houtei=case["houtei"], is_daburu_riichi=case["double_riichi"],
        is_tenhou=case["tenhou"], is_chiihou=case["chiihou"],
        player_wind=WINDS[case["jikaze"]], round_wind=WINDS[case["bakaze"]], options=options,
    )
    result = HandCalculator.estimate_hand_value(
        concealed + meld_tiles, win_tile, melds=melds, dora_indicators=dora, config=config,
        ura_dora_indicators=ura if case["riichi"] else None,
    )
    if result.error:
        return {"id": case["id"], "error": result.error}
    opened = any(m.opened for m in melds)
    yaku = []
    for y in result.yaku:
        han = y.han_open if opened else y.han_closed
        yaku.append([YAKU_NAMES.get(y.yaku_id, "py:" + y.name), han])
    cost = result.cost
    dealer = case["jikaze"] == "ton"
    if not case["tsumo"]:
        payments = {"ron": cost["main"]}
    elif dealer:
        payments = {"ko": cost["main"]}
    else:
        payments = {"oya": cost["main"], "ko": cost["additional"]}
    is_yakuman = any(y.is_yakuman for y in result.yaku)
    return {"id": case["id"], "yaku": yaku, "han": result.han, "fu": result.fu,
            "payments": payments, "yakuman": is_yakuman}


def main():
    cases = json.load(sys.stdin)
    out = []
    for case in cases:
        try:
            out.append(evaluate(case))
        except Exception as e:  # report, do not stop the batch
            out.append({"id": case["id"], "error": "exception: " + repr(e)})
    json.dump(out, sys.stdout)


if __name__ == "__main__":
    main()
