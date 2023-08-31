"use client";
import { useAtom, useAtomValue } from "jotai";
import { blazeInfo, openBuyTicketModal } from "@/data/atoms";
// Images
import Image from "next/image";
import flame from "@/../public/jackpot.png";
import loadingGif from "@/../public/assets/loading_flame.gif";
//  Contracts
import {
  erc20ABI,
  useAccount,
  useBalance,
  useContractReads,
  useContractWrite,
  usePrepareContractWrite,
  useToken,
  useWaitForTransaction,
} from "wagmi";
import {
  ShibToken,
  USDCToken,
  USDTToken,
  blazeToken,
  lotteryAbi,
  lotteryContract,
  uniswapV2PairAbi,
  usdtAbi,
} from "@/data/contracts";
import {
  BaseError,
  formatEther,
  formatUnits,
  parseEther,
  parseUnits,
  toHex,
  zeroAddress,
} from "viem";
import { useEffect, useState } from "react";
import { useImmer } from "use-immer";
import { BiSolidEdit } from "react-icons/bi";
import classNames from "classnames";
import TicketNumber from "./TicketNumber";

type TicketView = [number, number, number, number, number];
type TokenTypes = "blaze" | "eth" | "shib" | "usdt";

const tokenAddresses = {
  shib: ShibToken,
  usdc: USDCToken,
  usdt: USDTToken,
  eth: zeroAddress,
  blaze: blazeToken,
} as const;

const BuyTicketsModal = () => {
  const { address } = useAccount();
  const { data: tokenData } = useToken({ address: blazeToken, chainId: 1 });
  const { data: balanceData } = useBalance({
    address: address || zeroAddress,
  });
  const { data: balances, refetch: balanceRefetch } = useContractReads({
    contracts: [
      {
        address: blazeToken, //blazeToken,
        abi: erc20ABI,
        functionName: "balanceOf",
        args: [address || zeroAddress],
        chainId: 1,
      },
      {
        address: blazeToken, //blazeToken,
        abi: erc20ABI,
        functionName: "allowance",
        args: [address || zeroAddress, lotteryContract],
        chainId: 1,
      },
      {
        address: ShibToken, //blazeToken,
        abi: erc20ABI,
        functionName: "balanceOf",
        args: [address || zeroAddress],
        chainId: 1,
      },
      {
        address: ShibToken, //blazeToken,
        abi: erc20ABI,
        functionName: "allowance",
        args: [address || zeroAddress, lotteryContract],
        chainId: 1,
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "acceptedTokens",
        args: [zeroAddress],
        chainId: 1,
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "acceptedTokens",
        args: [ShibToken],
        chainId: 1,
      },
      {
        address: USDCToken,
        abi: erc20ABI,
        functionName: "balanceOf",
        args: [address || zeroAddress],
        chainId: 1,
      },
      {
        address: USDCToken,
        abi: erc20ABI,
        functionName: "allowance",
        args: [address || zeroAddress, lotteryContract],
        chainId: 1,
      },
      {
        address: "0x811beEd0119b4AfCE20D2583EB608C6F7AF1954f",
        abi: uniswapV2PairAbi,
        functionName: "getReserves",
        chainId: 1,
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "acceptedTokens",
        args: [USDCToken],
        chainId: 1,
      },
      {
        address: USDTToken,
        abi: erc20ABI,
        functionName: "balanceOf",
        args: [address || zeroAddress],
        chainId: 1,
      },
      {
        address: USDTToken,
        abi: erc20ABI,
        functionName: "allowance",
        args: [address || zeroAddress, lotteryContract],
        chainId: 1,
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "acceptedTokens",
        args: [USDTToken],
        chainId: 1,
      },
    ],
  });
  const roundInfo = useAtomValue(blazeInfo);
  const [tokenToUse, setTokenToUse] = useState<TokenTypes>("blaze");
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
  const { config: approveUSDTConfig } = usePrepareContractWrite({
    address: tokenAddresses.usdt,
    abi: usdtAbi,
    functionName: "approve",
    args: [lotteryContract, parseUnits("1000000", 6)],
  });
  const { config: approveConfig } = usePrepareContractWrite({
    address: tokenAddresses[tokenToUse], //selected Token,
    abi: erc20ABI,
    functionName: "approve",
    args: [
      lotteryContract,
      tokenToUse == "usdt"
        ? parseUnits("100000", 6)
        : tokenData?.totalSupply.value || parseEther("10000000000000000000"),
    ],
  });
  const { write: approveWrite, data: approveTxData } =
    useContractWrite(approveConfig);
  const { write: approveUSDTWrite, data: approveUSDTTxData } =
    useContractWrite(approveUSDTConfig);

  const { isLoading: approvePendingTx, isSuccess: approveSuccess } =
    useWaitForTransaction({ hash: approveTxData?.hash });
  const { isLoading: approveUSDTPendingTx, isSuccess: approveUSDTSuccess } =
    useWaitForTransaction({ hash: approveUSDTTxData?.hash });

  useEffect(() => {
    if (approveSuccess || approveUSDTSuccess) {
      const interval = setInterval(balanceRefetch, 15000);
      return () => clearInterval(interval);
    }
  }, [approveSuccess, approveUSDTSuccess, balanceRefetch]);
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

  const { config: buyWithAltConfig } = usePrepareContractWrite({
    address: lotteryContract,
    abi: lotteryAbi,
    functionName: "buyTicketsWithAltTokens",
    args: [ticketsInHex, tokenAddresses[tokenToUse]],
    chainId: 1,
    value:
      tokenToUse === "eth"
        ? BigInt(ticketAmount) *
            (
              balances?.[4]?.result as [
                bigint,
                bigint,
                bigint,
                bigint,
                bigint,
                bigint,
                `0x${string}`,
                boolean
              ]
            )?.[0] || 0n
        : 0n,
  });

  const { write, data, error, isError } = useContractWrite(config);
  const {
    write: buyWithAlt,
    data: altData,
    error: altError,
    isError: isBuyWithAltError,
  } = useContractWrite(buyWithAltConfig);
  const { isSuccess } = useWaitForTransaction({
    hash: data?.hash,
  });
  const { isSuccess: isBuyWithAltSuccess } = useWaitForTransaction({
    hash: altData?.hash,
  });

  const tokenInfo = {
    blaze: {
      wallet: (balances?.[0]?.result as bigint) || 0n,
      allowance: (balances?.[1]?.result as bigint) || 0n,
      decimals: 18,
      price: roundInfo.ticketPrice,
      tokenPrice: BigInt(Math.floor(roundInfo.price * 1e18)),
      priceDivisor: 1e18,
      symbol: "BLZE",
    },
    shib: {
      wallet: (balances?.[2]?.result as bigint) || 0n,
      allowance: (balances?.[3]?.result as bigint) || 0n,
      decimals: 18,
      price: ((balances?.[5]?.result as any) || [])?.[0] || 0n,
      tokenPrice:
        (((balances?.[8]?.result as any)?.[1] || 0n) * roundInfo.ethPrice) /
        ((balances?.[8]?.result as any)?.[0] || 1n),
      priceDivisor: 1e8,
      symbol: "SHIB",
    },
    usdc: {
      wallet: (balances?.[6]?.result as bigint) || 0n,
      allowance: (balances?.[7]?.result as bigint) || 0n,
      decimals: 6,
      tokenPrice: 10n ** 18n,
      price: ((balances?.[9]?.result as any) || [])?.[0] || 0n,
      priceDivisor: 1e6,
      symbol: "USDC",
    },
    usdt: {
      wallet: (balances?.[10]?.result as bigint) || 0n,
      allowance: (balances?.[11]?.result as bigint) || 0n,
      decimals: 6,
      tokenPrice: 10n ** 18n,
      price: ((balances?.[12]?.result as any) || [])?.[0] || 0n,
      priceDivisor: 1e6,
      symbol: "USDT",
    },
    eth: {
      wallet: (balanceData?.value as bigint) || 0n,
      allowance: 1n,
      decimals: 18,
      price: ((balances?.[4]?.result as any) || [])?.[0] || 0n,
      tokenPrice: roundInfo.ethPrice,
      symbol: "ETH",
      priceDivisor: 1e8,
    },
  };

  return (
    <dialog className="modal font-outfit" open={openModal}>
      <div className="modal-box bg-secondary-bg border-2 rounded-3xl border-golden">
        <div className="flex flex-row justify-between items-center">
          <h4 className="text-center text-2xl md:text-4xl font-bold">
            {(view == 0 && "Buy Tickets") ||
              (view == 1 && "Ready To Play") ||
              (view == 2 && "Pick Your Numbers") ||
              (view == 3 && "Buying Tickets")}
          </h4>
          <Image
            src={flame}
            alt="Jackpot logo"
            height={75}
            // width={55}
            // style={{ transform: "scaleX(-1)" }}
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
                  <td className="text-right">
                    <select
                      className="select select-sm select-primary"
                      value={tokenToUse}
                      onChange={(e) =>
                        setTokenToUse(e.target.value as TokenTypes)
                      }
                    >
                      <option disabled>Tokens Accepted</option>
                      <option value="blaze">$BLZE</option>
                      <option value="shib">$SHIB</option>
                      <option value="usdt">$USDT</option>
                      <option value="usdc">$USDC</option>
                      <option value="eth">$ETH</option>
                    </select>
                  </td>
                </tr>
                <tr className="border-slate-500">
                  <td>Ticket Price</td>
                  <td className="text-right text-golden/80">
                    {parseFloat(
                      formatUnits(
                        tokenInfo[tokenToUse].price,
                        tokenInfo[tokenToUse].decimals
                      )
                    ).toLocaleString()}
                    &nbsp;$
                    {tokenInfo[tokenToUse].symbol}
                  </td>
                </tr>
                <tr className="border-slate-500">
                  <td>Wallet</td>
                  <td className="text-right text-golden/80">
                    {parseFloat(
                      parseFloat(
                        formatUnits(
                          tokenInfo[tokenToUse].wallet,
                          tokenInfo[tokenToUse].decimals
                        )
                      ).toFixed(tokenToUse === "eth" ? 6 : 0)
                    ).toLocaleString(undefined, {
                      maximumFractionDigits: tokenToUse === "eth" ? 6 : 0,
                    })}
                    &nbsp;${tokenInfo[tokenToUse].symbol}
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
                    {(
                      ticketAmount *
                      parseFloat(
                        formatUnits(
                          tokenInfo[tokenToUse].price,
                          tokenInfo[tokenToUse].decimals
                        )
                      )
                    ).toLocaleString()}
                    &nbsp;${tokenInfo[tokenToUse].symbol}
                  </td>
                </tr>
                <tr className="border-slate-500 text-gray-500">
                  <td>Total USD</td>
                  <td className="text-right text-primary">
                    {(
                      (ticketAmount *
                        parseFloat(
                          formatEther(
                            tokenInfo[tokenToUse].price *
                              tokenInfo[tokenToUse].tokenPrice
                          )
                        )) /
                      (tokenInfo[tokenToUse].priceDivisor || 1)
                    ).toLocaleString()}
                    &nbsp;$USD
                  </td>
                </tr>
              </tbody>
            </table>
            <div className="flex flex-row items-center justify-center gap-x-4 p-4">
              {parseFloat(formatEther(tokenInfo[tokenToUse].allowance)) >
                (ticketAmount || 1) *
                  parseFloat(formatEther(tokenInfo[tokenToUse].price)) ||
              tokenToUse == "eth" ? (
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
                    (approvePendingTx || approveUSDTPendingTx) &&
                      "loading btn-disabled loading-spinner"
                  )}
                  onClick={() =>
                    tokenToUse == "usdt"
                      ? approveUSDTWrite?.()
                      : approveWrite?.()
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
                  if (tokenToUse !== "blaze") {
                    if (!buyWithAlt) return;
                    setView(3);
                    buyWithAlt();
                  } else {
                    if (!write) return;
                    setView(3);
                    write();
                  }
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

            {(isSuccess || isBuyWithAltSuccess) && (
              <div className="text-green-600/80 text-3xl">Tickets Bought!</div>
            )}
            {(isError || isBuyWithAltError) && (
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
