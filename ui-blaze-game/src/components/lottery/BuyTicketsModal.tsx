"use client";
import { useAtom, useAtomValue } from "jotai";
import { blazeInfo, openBuyTicketModal } from "@/data/atoms";
// Images
import Image from "next/image";
import logo from "@/../public/assets/SNG Jackpot 1.svg";
import loadingGif from "@/../public/assets/loading_j.gif";
//  Contracts
import { erc20Abi, getAddress } from "viem";
import {
  useAccount,
  useBalance,
  useReadContracts,
  useWriteContract,
} from "wagmi";
import {
  lotteryAbi,
  lotteryContract,
  uniRouter,
  uniRouterAbi,
  wbnb,
} from "@/data/contracts";
import {
  BaseError,
  formatUnits,
  maxUint256,
  parseEther,
  toHex,
  zeroAddress,
} from "viem";
import { useState } from "react";
import { useImmer } from "use-immer";
import { BiSolidEdit } from "react-icons/bi";
import classNames from "classnames";
import TicketNumber from "./TicketNumber";
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog";
import { Combobox } from "@/components/Combobox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

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
  const selectedData = tokenData.find(
    (token) => token.contract.toLowerCase() === tokenToUse.toLowerCase()
  );

  const { data: selectedTokenData, refetch: balanceRefetch } = useReadContracts(
    {
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
          functionName: "getAmountsIn",
          args: [roundInfo.ticketPriceBNB, [tokenToUse, wbnb]],
        },
      ],
      query: {
        enabled: tokenToUse !== zeroAddress || !selectedData,
      },
    }
  );
  const isNative = tokenToUse === wbnb || tokenToUse === zeroAddress;
  const tokenSymbol = selectedData?.symbol || selectedTokenData?.[3].result;
  const tokenTicketPrice = isNative
    ? roundInfo.ticketPriceBNB
    : selectedTokenData?.[4].result?.[0];
  const tokensInWallet =
    tokenToUse === zeroAddress
      ? parseInt((ethBalance?.value || 0n)?.toString()) / 1e18
      : parseInt((selectedTokenData?.[0].result || 0n)?.toString()) /
        10 ** parseInt((selectedTokenData?.[2].result || 0n)?.toString());
  const tokenDecimals = isNative
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

  const requiresApproval =
    tokenToUse !== zeroAddress &&
    (selectedTokenData?.[1]?.result || 0n) < ticketAmount * priceInToken;

  const sufficientFunds =
    tokenToUse === zeroAddress
      ? tokensInWallet >= ticketAmount * priceInToken
      : (selectedTokenData?.[1]?.result || 0n) >= ticketAmount * priceInToken;

  return (
    <Dialog
      open={openModal}
      onOpenChange={(newVal) => {
        reset();
        setOpenModal(newVal);
      }}
    >
      <DialogContent className="bg-secondary-bg border-2 rounded-4xl border-secondary-light-bg card-highlight max-h-[80vh] overflow-auto">
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
                          value: `${token.contract.toLocaleLowerCase()}::${token.symbol.toLocaleLowerCase()}::${token.name.toLocaleLowerCase()}`,
                          label: token.symbol,
                          imageUrl: token.image,
                        })) || []
                      }
                      value={`${selectedData?.contract.toLocaleLowerCase()}::${selectedData?.symbol.toLocaleLowerCase()}::${selectedData?.name.toLocaleLowerCase()}`}
                      onChange={(value) => {
                        console.log(
                          "onchange value: ",
                          value,
                          getAddress(value.split("::")[0] as `0x${string}`)
                        );
                        setTokenToUse(
                          getAddress(value.split("::")[0] as `0x${string}`)
                        );
                      }}
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
                <tr className="border-red-500/30">
                  <td colSpan={2}>
                    <div className="flex flex-col items-center w-full">
                      <div className="grid w-[200px] items-center gap-1.5">
                        <Label htmlFor="ticketAmount">Number of Tickets</Label>
                        <Input
                          type="number"
                          id="ticketAmount"
                          placeholder="Tickets to buy"
                          onFocus={(e) => e.target.select()}
                          value={ticketAmount}
                          onChange={(e) => {
                            // only integers
                            const num = parseInt(e.target.value);
                            if (isNaN(num)) setTicketAmount(0);
                            else setTicketAmount(num);
                          }}
                        />
                      </div>
                    </div>
                  </td>
                </tr>

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
            <div className="flex flex-row items-center justify-center gap-x-4 p-4 flex-wrap">
              {!requiresApproval ? (
                <>
                  <button
                    className="btn btn-primary btn-sm rounded-full font-light min-w-[126px]"
                    disabled={ticketAmount < 1 || !sufficientFunds}
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
                    className="btn btn-primary rounded-full font-light btn-sm min-w-[126px]"
                    disabled={ticketAmount < 1 || !sufficientFunds}
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
                  {!sufficientFunds && (
                    <div className="text-red-500 w-full text-center text-sm pt-3">
                      Insufficient funds
                    </div>
                  )}
                </>
              ) : (
                <button
                  className={classNames(
                    "btn btn-primary rounded-full font-light btn-sm min-w-[126px]"
                  )}
                  disabled={isPending}
                  onClick={() =>
                    writeContract(
                      {
                        address: tokenToUse,
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
                  {isPending ? (
                    <span className="loading loading-spinner"></span>
                  ) : (
                    "Approve Game"
                  )}
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
            <div className="flex flex-col gap-y-4 py-4 max-h-[60vh] overflow-auto">
              {allTickets.map((ticket, i) => {
                return (
                  <div key={`ticket-id-to-buy-${i}`}>
                    <div className="text-sm text-primary pb-4 flex flex-row justify-between items-center">
                      <div>Ticket #{i + 1}</div>
                      <button
                        className="btn rounded-full btn-secondary bg-transparent text-primary btn-sm text-xs font-light"
                        onClick={() => {
                          setSelectedTicket(i);
                          setSelectedNumbers(ticket);
                          setView(2);
                        }}
                      >
                        Edit ticket
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
            <div className="flex flex-row items-center justify-center">
              <button
                className="btn btn-primary rounded-full"
                onClick={() => {
                  // @todo ADD VALUE WHEN BUYING WITH NATIVE
                  setView(3);
                  writeContract({
                    address: lotteryContract,
                    abi: lotteryAbi,
                    functionName: "buyTickets",
                    args: [ticketsInHex, tokenToUse],
                    value:
                      tokenToUse === zeroAddress
                        ? parseEther(
                            (ticketAmount * priceInToken * 1.1).toString()
                          )
                        : undefined,
                  });
                }}
              >
                Buy Now
              </button>
            </div>
          </>
        )}
        {view == 2 && (
          <>
            <div>
              <div className="border-2 border-primary flex flex-row items-center justify-center rounded-3xl my-4 bg-dark-red">
                {selectedNumbers.map((num, i) => {
                  return (
                    <button
                      key={`ticket-id-to-buy-${selectedTicket}-${i}`}
                      className="relative hover:bg-white/70 p-2 md:p-4 rounded-full"
                      onClick={() => {
                        if (selectedIndex !== i) setSelectedIndex(i);
                      }}
                    >
                      <TicketNumber number={num} variation="secondary" />
                      {selectedIndex == i && (
                        <div className="absolute border-r-8 border-l-8 border-b-8 md:border-b-[16px] border-t-0 border-transparent border-b-red-500 w-0 h-0 ml-2 md:ml-4" />
                      )}
                    </button>
                  );
                })}
              </div>
              <div className="grid  grid-cols-6 gap-y-2 max-h-[320px] overflow-y-auto">
                {Array.from({ length: 64 }).map((_, i) => {
                  const currentNumberIsSelected = selectedNumbers.includes(i);
                  return (
                    <div
                      key={`ticket-id-to-buy-${selectedTicket}-${i}`}
                      className="flex items-center justify-center"
                    >
                      <button
                        className={classNames(
                          "hover:bg-golden/70 p-1 rounded-full",
                          currentNumberIsSelected && "bg-red-500/70"
                        )}
                        onClick={() => {
                          // if number is selected, remove it
                          if (currentNumberIsSelected) {
                            setAllTickets((draft) => {
                              draft[selectedTicket][selectedIndex] = 0;
                            });
                            setAllTickets((draft) => {
                              draft[selectedTicket][selectedIndex] = 0;
                            });
                            return;
                          }

                          setAllTickets((draft) => {
                            draft[selectedTicket][selectedIndex] = i;
                          });
                          setSelectedNumbers((draft) => {
                            draft[selectedIndex] = i;
                          });
                          setSelectedIndex((i) => (i + 1) % 5);
                        }}
                      >
                        <TicketNumber
                          number={i}
                          variation={
                            currentNumberIsSelected ? "selected" : "default"
                          }
                        />
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
                href={`https://bscscan.com/tx/${data || ""}`}
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
            className="btn btn-ghost btn-secondary rounded-full mt-4"
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
    </Dialog>
  );
};

export default BuyTicketsModal;
