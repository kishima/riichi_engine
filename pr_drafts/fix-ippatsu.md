# Clear the ippatsu chance on the riichi player's next discard

Branch: `fix/ippatsu`

## What is wrong

`ippatsu_flags[seat]` is set by `process_riichi` and cleared only by calls and
kans (`clear_ippatsu_flags`). Without any call the flag stays for the rest of
the hand, and every later win of that player counts ippatsu.

## Reproduce

Seat 0 in riichi with `ippatsu_flags[0] = true` discards normally: the flag is
still true (spec "一発はリーチした本人の次の打牌でクリアされる"). Another seat's
flag must stay; the discard that declares riichi keeps it (second spec).

## Fix

`process_dahai` clears the flag of the discarding seat when it is in riichi,
except for the declaring discard (`action[:riichi]`).

## Rule

Ippatsu holds until the player's own next discard: a ron on any discard before
it, or the tsumo of the next draw, still counts; any call (including a closed
kan) ends it, as the engine already does. This is the Tenhou and M-League rule.

## Compatibility

Wins after the first go-around no longer get ippatsu. No API change.

---

一発がリーチした本人の次の打牌で消えなかった (鳴きと槓でしか消えない)。次の打牌で消すようにした (宣言牌では消さない)。
