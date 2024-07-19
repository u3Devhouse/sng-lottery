"use client";
import { useAtom, useAtomValue } from "jotai";
import { blazeInfo, openBuyTicketModal } from "@/data/atoms";
// Images
import Image from "next/image";
import logo from "@/../public/assets/SNG Jackpot 1.svg";
import loadingGif from "@/../public/assets/loading_flame.gif";
//  Contracts
import { erc20Abi } from "viem";
import {
  useAccount,
  useBalance,
  useReadContract,
  useReadContracts,
  useWriteContract,
} from "wagmi";
import {
  lotteryAbi,
  lotteryContract,
  uniswapV2PairAbi,
  uniRouter,
  uniRouterAbi,
} from "@/data/contracts";
import {
  BaseError,
  formatEther,
  formatUnits,
  maxUint256,
  parseEther,
  parseUnits,
  toHex,
  zeroAddress,
} from "viem";
import { useEffect, useMemo, useState } from "react";
import { useImmer } from "use-immer";
import { BiSolidEdit } from "react-icons/bi";
import classNames from "classnames";
import TicketNumber from "./TicketNumber";
import useAcceptedTokens, {
  AcceptedTokens,
  acceptedTokens,
  tokenList,
} from "@/hooks/useAcceptedTokens";

import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectLabel,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Combobox } from "../Combobox";

type TicketView = [number, number, number, number, number];

export type TokenData = {
  contract: string;
  name: string;
  symbol: string;
  decimal: number;
  image: string;
};

const BuyTicketsModal = ({ tokenData }: { tokenData: Array<TokenData> }) => {
  const { address } = useAccount();
  const { data: ethBalance } = useBalance({ address });

  const roundInfo = useAtomValue(blazeInfo);
  const [tokenToUse, setTokenToUse] = useState<`0x${string}`>(zeroAddress);
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
  const selectedData = tokenData.find((token) => token.contract === tokenToUse);

  const { data: selectedTokenData } = useReadContracts({
    contracts: [
      {
        address: tokenToUse,
        abi: erc20Abi,
        functionName: "balanceOf",
        args: [address || zeroAddress],
      },
      {
        address: tokenToUse,
        abi: erc20Abi,
        functionName: "allowance",
        args: [address || zeroAddress, lotteryContract],
      },
      {
        address: tokenToUse,
        abi: erc20Abi,
        functionName: "decimals",
      },
      {
        address: tokenToUse,
        abi: erc20Abi,
        functionName: "symbol",
      },
      {
        address: uniRouter,
        abi: uniRouterAbi,
        functionName: "getAmountsOut",
        args: [1000000000000000000n, [tokenToUse, zeroAddress]],
      },
    ],
    query: {
      enabled: tokenToUse !== zeroAddress || !selectedData,
    },
  });

  const tokenSymbol = selectedData?.symbol || selectedTokenData?.[3].result;
  const tokenTicketPrice =
    tokenToUse === zeroAddress
      ? roundInfo.ticketPriceBNB
      : selectedTokenData?.[4].result?.[1];
  const tokensInWallet =
    tokenToUse === zeroAddress
      ? parseInt((ethBalance?.value || 0n)?.toString()) / 1e18
      : parseInt((selectedTokenData?.[0].result || 0n)?.toString()) /
        10 ** parseInt((selectedTokenData?.[3].result?.[0] || 0n)?.toString());
  const tokenDecimals =
    tokenToUse === zeroAddress
      ? 18
      : selectedData
      ? selectedData.decimal
      : selectedTokenData?.[2].result || 18;
  const priceInToken =
    parseFloat((tokenTicketPrice || 0n)?.toString()) / 10 ** tokenDecimals;
  // --------------------
  // Approve Blaze in lottery
  // --------------------
  const { writeContract, data, isPending, isError, error, isSuccess } =
    useWriteContract();

  // const { config: approveConfig, error: approveConfigErr } =
  //   usePrepareContractWrite({
  //     address: acceptedTokens[tokenToUse].address as `0x${string}`, //selected Token,
  //     abi: erc20Abi,
  //     functionName: "approve",
  //     args: [lotteryContract, maxUint256],
  //     enabled: tokenToUse !== "eth",
  //   });

  // console.log(approveConfigErr);
  // const { write: approveWrite, data: approveTxData } =
  //   useContractWrite(approveConfig);
  // // const { write: approveUSDTWrite, data: approveUSDTTxData } =
  // //   useContractWrite(approveUSDTConfig);

  // const { isLoading: approvePendingTx, isSuccess: approveSuccess } =
  //   useWaitForTransaction({ hash: approveTxData?.hash });
  // // const { isLoading: approveUSDTPendingTx, isSuccess: approveUSDTSuccess } =
  // //   useWaitForTransaction({ hash: approveUSDTTxData?.hash });

  // useEffect(() => {
  //   if (approveSuccess) {
  //     const interval = setInterval(balanceRefetch, 15000);
  //     return () => clearInterval(interval);
  //   }
  // }, [approveSuccess, balanceRefetch]);
  // --------------------
  // BUY TICKETS
  // --------------------
  // const {
  //   config,
  //   error: prepErr,
  //   data: prepData,
  // } = usePrepareContractWrite({
  //   address: lotteryContract,
  //   abi: lotteryAbi,
  //   functionName: "buyTickets",
  //   args: [ticketsInHex],
  //   enabled: tokenToUse === "blze",
  // });

  // const { config: buyWithAltConfig } = usePrepareContractWrite({
  //   address: lotteryContract,
  //   abi: lotteryAbi,
  //   functionName: "buyTicketsWithAltTokens",
  //   args: [ticketsInHex, acceptedTokens[tokenToUse].address as `0x${string}`],
  //   chainId: 1,
  //   value:
  //     tokenToUse === "eth"
  //       ? BigInt(ticketAmount) * (selectedTokenData?.[3]?.result?.[0] || 0n)
  //       : 0n,
  //   enabled: tokenToUse !== "blze",
  // });

  // const { write, error, isError } = useContractWrite(config);
  // const {
  //   write: buyWithAlt,
  //   data: altData,
  //   error: altError,
  //   isError: isBuyWithAltError,
  // } = useContractWrite(buyWithAltConfig);
  // const { isSuccess } = useWaitForTransaction({
  //   hash: data?.hash,
  // });
  // const { isSuccess: isBuyWithAltSuccess } = useWaitForTransaction({
  //   hash: altData?.hash,
  // });

  // console.log(selectedTokenData);
  // console.log({
  //   isApproved:
  //     (selectedTokenData?.[1]?.result || 0n) >=
  //     BigInt(ticketAmount) * (selectedTokenData?.[3]?.result?.[0] || 0n),
  //   allowance: selectedTokenData?.[1]?.result || 0n,
  //   priceAmount:
  //     BigInt(ticketAmount) * (selectedTokenData?.[3]?.result?.[0] || 0n),
  // });

  return (
    <Dialog
      open={openModal}
      onOpenChange={(newVal) => {
        reset();
        setOpenModal(newVal);
      }}
    >
      <DialogContent className="bg-secondary-bg border-2 rounded-4xl border-secondary-light-bg card-highlight">
        <DialogTitle className="flex flex-row justify-between items-center">
          <Image src={logo} alt="Jackpot logo" height={75} />
          <div className="text-center text-2xl font-bold italic text-secondary-light-bg">
            {(view == 0 && "Buy Tickets") ||
              (view == 1 && "Ready To Play") ||
              (view == 2 && "Pick Your Numbers") ||
              (view == 3 && "Buying Tickets")}
          </div>
        </DialogTitle>
        {view == 0 && (
          <>
            <table className="table mt-4">
              <tbody>
                <tr className="border-red-500/30">
                  <td>ROUND</td>
                  <td className="text-right">{roundInfo.currentRound}</td>
                </tr>
                <tr className="border-red-500/30">
                  <td>Buy with</td>
                  <td className="flex items-end justify-end px-0">
                    <Combobox
                      placeholder="Select a Token"
                      options={
                        tokenData?.map((token) => ({
                          value: token.contract,
                          label: token.symbol,
                          imageUrl: token.image,
                        })) || []
                      }
                      value={tokenToUse}
                      onChange={(value) =>
                        setTokenToUse(value as `0x${string}`)
                      }
                    />
                  </td>
                </tr>
                <tr className="border-red-500/30">
                  <td>Ticket Price</td>
                  <td className="text-right text-primary">
                    {parseFloat(
                      formatUnits(roundInfo.ticketPrice, 18)
                    ).toLocaleString(undefined, { maximumFractionDigits: 2 })}
                    &nbsp;$USD
                  </td>
                </tr>
                <tr className="border-red-500/30">
                  <td>Price in Token</td>
                  <td className="text-right text-primary">
                    {priceInToken?.toLocaleString(undefined, {
                      maximumFractionDigits: 6,
                    }) || "-"}
                    &nbsp;$
                    {tokenSymbol}
                  </td>
                </tr>
                <tr className="border-red-500/30">
                  <td>Wallet</td>
                  <td className="text-right text-secondary-light-bg/80">
                    {tokensInWallet.toLocaleString(undefined, {
                      maximumFractionDigits: 6,
                    })}
                    &nbsp;$
                    {tokenSymbol}
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
                <tr className="border-red-500/30 text-gray-500">
                  <td>Total</td>
                  <td className="text-right text-secondary-light-bg">
                    {(parseFloat((tokenTicketPrice || 0n)?.toString()) *
                      ticketAmount) /
                      10 ** tokenDecimals}
                    &nbsp;$
                    {tokenSymbol}
                  </td>
                </tr>
                <tr className="border-red-500/30 text-gray-500">
                  <td>Total USD</td>
                  <td className="text-right text-primary">
                    {(
                      ticketAmount *
                      parseFloat(formatUnits(roundInfo.ticketPrice, 18))
                    ).toLocaleString(undefined, { maximumFractionDigits: 6 })}
                    &nbsp;$USD
                  </td>
                </tr>
              </tbody>
            </table>
            <div className="flex flex-row items-center justify-center gap-x-4 p-4">
              {(selectedTokenData?.[1]?.result || 0n) >=
              BigInt(ticketAmount) *
                (selectedTokenData?.[3]?.result?.[0] || 0n) ? (
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
                            while (ticket.includes(num) && i > 0) {
                              num = Math.floor(Math.random() * 63);
                            }
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
                    isPending && "loading btn-disabled loading-spinner"
                  )}
                  onClick={() =>
                    writeContract(
                      {
                        address: acceptedTokens[tokenToUse]
                          .address as `0x${string}`, //selected Token,
                        abi: erc20Abi,
                        functionName: "approve",
                        args: [lotteryContract, maxUint256],
                      },
                      {
                        onSuccess: () => {
                          balanceRefetch();
                        },
                      }
                    )
                  }
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
                  // @todo ADD VALUE WHEN BUYING WITH NATIVE
                  setView(3);
                  writeContract({
                    address: lotteryContract,
                    abi: lotteryAbi,
                    functionName: "buyTicketsWithAltTokens",
                    args: [
                      ticketsInHex,
                      acceptedTokens[tokenToUse].address as `0x${string}`,
                    ],
                  });
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
                href={`https://etherscan.io/tx/${data || ""}`}
              >
                <strong>Tx:</strong>{" "}
                {data
                  ? data.substring(0, 4) +
                    "..." +
                    data.substring(data.length - 4)
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
      </DialogContent>
      {/* <div
        className="modal-backdrop bg-slate-700/30 backdrop-blur-sm"
        onClick={reset}
      /> */}
    </Dialog>
  );
};

export default BuyTicketsModal;
