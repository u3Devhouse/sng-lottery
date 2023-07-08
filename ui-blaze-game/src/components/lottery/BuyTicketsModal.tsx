"use client";
import { useAtom, useAtomValue } from "jotai";
import { blazeInfo, openBuyTicketModal } from "@/data/atoms";
// Images
import Image from "next/image";
import flame from "@/../public/assets/tiny_flame.png";
import loadingGif from "@/../public/assets/loading_flame.gif";
//  Contracts
import {
  erc20ABI,
  useAccount,
  useContractReads,
  useContractWrite,
  usePrepareContractWrite,
  useToken,
  useWaitForTransaction,
} from "wagmi";
import { blazeToken, lotteryAbi, lotteryContract } from "@/data/contracts";
import { BaseError, formatEther, parseEther, toHex, zeroAddress } from "viem";
import { useEffect, useState } from "react";
import { useImmer } from "use-immer";
import { BiSolidEdit } from "react-icons/bi";
import classNames from "classnames";
import TicketNumber from "./TicketNumber";

type TicketView = [number, number, number, number, number];

const BuyTicketsModal = () => {
  const { address } = useAccount();
  const { data: tokenData } = useToken({ address: blazeToken, chainId: 1 });
  const { data: blazeBalance, refetch: balanceRefetch } = useContractReads({
    contracts: [
      {
        address: blazeToken, //blazeToken,
        abi: erc20ABI,
        functionName: "balanceOf",
        args: [address || zeroAddress],
      },
      {
        address: blazeToken, //blazeToken,
        abi: erc20ABI,
        functionName: "allowance",
        args: [address || zeroAddress, lotteryContract],
      },
    ],
  });
  const roundInfo = useAtomValue(blazeInfo);
  const [openModal, setOpenModal] = useAtom(openBuyTicketModal);
  const [ticketAmount, setTicketAmount] = useState(0);
  const [allTickets, setAllTickets] = useImmer<Array<TicketView>>([]);
  const [selectedTicket, setSelectedTicket] = useState<number>(0);
  const [selectedNumbers, setSelectedNumbers] = useImmer<TicketView>([
    0, 0, 0, 0, 0,
  ]);
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const [view, setView] = useState(0);

  const reset = () => {
    setTicketAmount(0);
    setAllTickets([]);
    setView(0);
    setOpenModal(false);
  };

  const ticketsInHex = allTickets.map((ticket) =>
    BigInt(
      "0x" +
        ticket
          .map((number) => toHex(number, { size: 1 }).replace("0x", ""))
          .join("")
    )
  );

  // --------------------
  // Approve Blaze in lottery
  // --------------------
  const { config: approveConfig } = usePrepareContractWrite({
    address: blazeToken, //blazeToken,
    abi: erc20ABI,
    functionName: "approve",
    args: [
      lotteryContract,
      tokenData?.totalSupply.value || parseEther("10000000000000000000"),
    ],
  });
  const { write: approveWrite, data: approveTxData } =
    useContractWrite(approveConfig);
  const {
    data: approveReceipt,
    isLoading: approvePendingTx,
    isSuccess: approveSuccess,
  } = useWaitForTransaction({ hash: approveTxData?.hash });

  useEffect(() => {
    if (approveSuccess) balanceRefetch();
  }, [approveSuccess, balanceRefetch]);
  // --------------------
  // BUY TICKETS
  // --------------------
  const {
    config,
    error: prepErr,
    data: prepData,
  } = usePrepareContractWrite({
    address: lotteryContract,
    abi: lotteryAbi,
    functionName: "buyTickets",
    args: [ticketsInHex],
  });

  const { write, data, error, isError } = useContractWrite(config);
  const { isSuccess } = useWaitForTransaction({
    hash: data?.hash,
  });

  return (
    <dialog className="modal font-outfit" open={openModal}>
      <div className="modal-box bg-secondary-bg border-2 rounded-3xl border-golden">
        <div className="flex flex-row justify-evenly items-center">
          <Image src={flame} alt="Ticket Fire" height={55} width={55} />
          <h4 className="text-center text-2xl md:text-4xl font-bold">
            {(view == 0 && "Buy Tickets") ||
              (view == 1 && "Ready To Play") ||
              (view == 2 && "Pick Your Numbers") ||
              (view == 3 && "Buying Tickets")}
          </h4>
          <Image
            src={flame}
            alt="Ticket Fire"
            height={55}
            width={55}
            style={{ transform: "scaleX(-1)" }}
          />
        </div>
        {view == 0 && (
          <>
            <table className="table mt-4">
              <tbody>
                <tr className="border-slate-500">
                  <td>ROUND</td>
                  <td className="text-right">{roundInfo.currentRound}</td>
                </tr>
                <tr className="border-slate-500">
                  <td>Buy with</td>
                  <td className="text-right">$BLZE</td>
                </tr>
                <tr className="border-slate-500">
                  <td>Ticket Price</td>
                  <td className="text-right text-golden/80">
                    {roundInfo.ticketPrice.toLocaleString()}&nbsp;$BLZE
                  </td>
                </tr>
                <tr className="border-slate-500">
                  <td>Wallet</td>
                  <td className="text-right text-golden/80">
                    {(
                      (blazeBalance?.[0]?.result || 0n) /
                      10n ** 15n
                    ).toLocaleString()}
                    &nbsp;$BLZE
                  </td>
                </tr>
              </tbody>
            </table>

            <input
              type="number"
              className="input input-bordered input-secondary w-full"
              onFocus={(e) => e.target.select()}
              value={ticketAmount}
              onChange={(e) => {
                // only integers
                const num = parseInt(e.target.value);
                if (isNaN(num)) setTicketAmount(0);
                else setTicketAmount(num);
              }}
            />

            <table className="table mt-4">
              <tbody>
                <tr className="border-slate-500 text-gray-500">
                  <td>Total</td>
                  <td className="text-right text-golden">
                    {(ticketAmount * roundInfo.ticketPrice).toLocaleString()}
                    &nbsp;$BLZE
                  </td>
                </tr>
              </tbody>
            </table>
            <div className="flex flex-row items-center justify-center gap-x-4 p-4">
              {parseFloat(formatEther(blazeBalance?.[1]?.result || 0n)) >
              (ticketAmount || 1) * roundInfo?.ticketPrice ? (
                <>
                  <button
                    className="btn btn-secondary btn-sm min-w-[126px]"
                    disabled={ticketAmount < 1}
                    onClick={() => {
                      setView(1);
                      setAllTickets(
                        new Array(ticketAmount).fill([0, 0, 0, 0, 0])
                      );
                    }}
                  >
                    Pick Numbers
                  </button>
                  <button
                    className="btn btn-secondary btn-sm min-w-[126px]"
                    disabled={ticketAmount < 1}
                    onClick={() => {
                      setView(1);
                      const newTickets = new Array(ticketAmount)
                        .fill([0, 0, 0, 0, 0])
                        .map(() => {
                          const ticket: TicketView = [0, 0, 0, 0, 0];
                          for (let i = 0; i < 5; i++) {
                            let num = Math.floor(Math.random() * 63);
                            ticket[i] = num;
                          }
                          return ticket;
                        });

                      setAllTickets(newTickets);
                    }}
                  >
                    Lucky Dip
                  </button>
                </>
              ) : (
                <button
                  className={classNames(
                    "btn btn-secondary btn-sm min-w-[126px]",
                    approvePendingTx && "loading btn-disabled loading-spinner"
                  )}
                  onClick={(e) => approveWrite?.()}
                >
                  Approve Game
                </button>
              )}
            </div>
            <p className="text-sm text-gray-500 text-justify whitespace-pre-wrap">
              <strong>Pick Numbers</strong>: sets all tickets to the value of
              &quot;00 00 00 00 00&quot;. Customize your tickets to your taste.
              {"\n"}
              <strong>Lucky Dip</strong>: sets all tickets to non repeating
              random values on this purchase.
              {"\n"}
              <strong>All purchases are final</strong>
            </p>
          </>
        )}
        {view == 1 && (
          <>
            <div className="flex flex-row items-center justify-center">
              <button
                className="btn btn-secondary"
                onClick={() => {
                  if (!write) return;
                  setView(3);
                  write();
                }}
              >
                Buy Now
              </button>
            </div>
            <div className="flex flex-col gap-y-4 py-4">
              {allTickets.map((ticket, i) => {
                return (
                  <div key={`ticket-id-to-buy-${i}`}>
                    <div className="text-sm text-golden pb-2 flex flex-row justify-between items-center">
                      <div>Ticket #{i + 1}</div>
                      <button
                        className="btn btn-circle btn-secondary bg-transparent text-golden btn-sm"
                        onClick={() => {
                          setSelectedTicket(i);
                          setSelectedNumbers(ticket);
                          setView(2);
                        }}
                      >
                        <BiSolidEdit />
                      </button>
                    </div>
                    <div className="flex flex-row items-center justify-center gap-x-4">
                      {ticket.map((num, j) => {
                        return (
                          <TicketNumber
                            number={num}
                            key={`ticket-id-to-buy-${i}-${j}`}
                          />
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>
          </>
        )}
        {view == 2 && (
          <>
            <div>
              <div className="border-2 border-golden flex flex-row items-center justify-center rounded-3xl my-4">
                {selectedNumbers.map((num, i) => {
                  return (
                    <button
                      key={`ticket-id-to-buy-${selectedTicket}-${i}`}
                      className="relative hover:bg-white/70 p-2 md:p-4 rounded-full"
                      onClick={() => {
                        if (selectedIndex !== i) setSelectedIndex(i);
                      }}
                    >
                      <TicketNumber number={num} />
                      {selectedIndex == i && (
                        <div className="absolute border-r-8 border-l-8 border-b-8 md:border-b-[16px] border-t-0 border-transparent border-b-red-500 w-0 h-0 ml-2 md:ml-4" />
                      )}
                    </button>
                  );
                })}
              </div>
              <div className="grid  grid-cols-6 gap-y-2 max-h-[320px] overflow-y-auto">
                {Array.from({ length: 64 }).map((_, i) => {
                  return (
                    <div
                      key={`ticket-id-to-buy-${selectedTicket}-${i}`}
                      className="flex items-center justify-center"
                    >
                      <button
                        className={classNames(
                          "hover:bg-golden/70 p-1 rounded-full",
                          selectedNumbers.includes(i) && "bg-red-500/70"
                        )}
                        onClick={() => {
                          setAllTickets((draft) => {
                            draft[selectedTicket][selectedIndex] = i;
                          });
                          setSelectedNumbers((draft) => {
                            draft[selectedIndex] = i;
                          });
                          setSelectedIndex((i) => (i + 1) % 5);
                        }}
                      >
                        <TicketNumber number={i} />
                      </button>
                    </div>
                  );
                })}
              </div>
            </div>
          </>
        )}
        {view == 3 && (
          <div className="flex flex-col items-center justify-center">
            <Image src={loadingGif} alt="Loading..." />
            <div>
              <a
                className="text-golden underline"
                href={`https://etherscan.io/tx/${data?.hash || ""}`}
              >
                <strong>Tx:</strong>{" "}
                {data?.hash
                  ? data?.hash.substring(0, 4) +
                    "..." +
                    data?.hash.substring(data?.hash.length - 4)
                  : "Pending Signature"}
              </a>
            </div>

            {isSuccess && (
              <div className="text-green-600/80 text-3xl">Tickets Bought!</div>
            )}
            {isError && (
              <div className="text-red-600/80">
                {(error as BaseError)?.shortMessage}
              </div>
            )}
          </div>
        )}
        {(view == 1 || view == 2 || (view == 3 && isError)) && (
          <button
            className="btn btn-outline btn-secondary w-full mt-4"
            onClick={() =>
              setView((v) => {
                if (v == 3) return 1;
                return v - 1;
              })
            }
          >
            Back
          </button>
        )}
      </div>
      <div
        className="modal-backdrop bg-slate-700/30 backdrop-blur-sm"
        onClick={reset}
      />
    </dialog>
  );
};

export default BuyTicketsModal;
