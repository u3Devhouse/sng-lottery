import { BigNumber } from "ethers";

export const convertToHex = (ticket: Array<number>) => {
    const hexArray = ticket.map(num => num.toString(16).padStart(2, '0'));
    return BigNumber.from("0x" + hexArray.join(''));
}