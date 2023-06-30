import { toHex } from "viem"

export const stringify: typeof JSON.stringify = (value, replacer, space) =>
  JSON.stringify(
    value,
    (key, value_) => {
      const value = typeof value_ === 'bigint' ? value_.toString() : value_
      return typeof replacer === 'function' ? replacer(key, value) : value
    },
    space,
  )

export const toEvenHexNoPrefix = (num: bigint) => {
  const hex = toHex(num).replace("0x", "");
  const adjusted = hex.length % 2 === 0 ? hex : `0${hex}`;
  if(adjusted.length !== 10)
    return adjusted.padStart(10, "0");
  return adjusted;
}