"use client";
import { useAtom } from "jotai";
import { openBuyTicketModal } from "@/data/atoms";
// Images
import Image from "next/image";
import flame from "@/../public/assets/tiny_flame.png";

const BuyTicketsModal = () => {
  const [openModal, setOpenModal] = useAtom(openBuyTicketModal);

  return (
    <dialog className="modal" open={openModal}>
      <div className="modal-box bg-secondary-bg border-2 rounded-3xl border-golden">
        <div className="flex flex-row justify-evenly items-center">
          <Image src={flame} alt="Ticket Fire" height={55} width={55} />
          <h4 className="text-center text-4xl font-outfit font-bold">
            Buy Tickets
          </h4>
          <Image src={flame} alt="Ticket Fire" height={55} width={55} />
        </div>
      </div>
      <div
        className="modal-backdrop bg-slate-700/30"
        onClick={() => setOpenModal(false)}
      />
    </dialog>
  );
};

export default BuyTicketsModal;
