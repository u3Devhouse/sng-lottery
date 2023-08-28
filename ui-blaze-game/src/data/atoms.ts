
import { atom } from 'jotai'

export const blazeInfo = atom({
  price: 0,
  ticketPrice: 0n,
  currentRound: 0,
  ethPrice: 0n,
})

export const openBuyTicketModal = atom(false)