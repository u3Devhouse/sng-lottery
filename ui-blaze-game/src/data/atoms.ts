
import { atom } from 'jotai'

export const blazeInfo = atom({
  price: 0,
  ticketPrice: 0,
  currentRound: 0,
})

export const openBuyTicketModal = atom(false)