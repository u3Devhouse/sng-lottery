"use client";
import Image from "next/image";
import { useEffect, useRef, useState } from "react";
import format from "date-fns/format";
import { useAtom, useSetAtom } from "jotai";
// Contracts
import { useAccount, useReadContract, useReadContracts } from "wagmi";
import { formatEther, toHex, zeroAddress } from "viem";
import {
  lotteryAbi,
  lotteryContract,
  uniswapPairAbi,
  blazePair,
  ethPriceFeed,
  priceFeedAbi,
} from "@/data/contracts";
// Images
import flyingTokens from "@/../public/assets/flying_tokens.png";
//  Data
import { blazeInfo, openBuyTicketModal } from "@/data/atoms";
import TicketNumber from "./TicketNumber";
import { toEvenHexNoPrefix } from "@/utils/stringify";
import { GrView } from "react-icons/gr";
import classNames from "classnames";
import redStar from "@/../public/assets/RedStar.svg";

const Card = () => {
  const [openMyTickets, setOpenMyTickets] = useState(false);
  const setOpenBuyTicketModal = useSetAtom(openBuyTicketModal);
  const [blazeData, setBlazeInfo] = useAtom(blazeInfo);
  const { address } = useAccount();
  const { data: currentRound, refetch: currentRoundRefetch } = useReadContract({
    address: lotteryContract,
    abi: lotteryAbi,
    functionName: "currentRound",
  });
  const { data: roundInfo, refetch: roundInfoRefetch } = useReadContracts({
    contracts: [
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "roundInfo",
        args: [currentRound || 0n],
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "getUserTickets",
        args: [address || zeroAddress, currentRound || 0n],
      },
      {
        address: blazePair,
        abi: uniswapPairAbi,
        functionName: "getReserves",
        chainId: 1,
      },
      {
        address: ethPriceFeed,
        abi: priceFeedAbi,
        functionName: "latestRoundData",
        chainId: 1,
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "roundDistribution",
        args: [currentRound || 0n],
      },
    ],
  });

  const roundIsActive = (roundInfo?.[0]?.result as any)?.[5] || false;

  useEffect(() => {
    setBlazeInfo({
      price:
        (Number((roundInfo?.[2]?.result as any)?.[1] || 0) *
          (Number((roundInfo?.[3]?.result as any)?.[1] || 0n) / 1e8)) /
        Number((roundInfo?.[2]?.result as any)?.[0] || 1),
      ticketPrice: (roundInfo?.[0]?.result as any)?.[2] || 0n,
      currentRound: Number(currentRound?.toString() || 0),
      ethPrice: (roundInfo?.[3]?.result as any)?.[1] || 0n,
    });
  }, [setBlazeInfo, roundInfo, currentRound]);

  useEffect(() => {
    const interval = setInterval(() => {
      void currentRoundRefetch();
      void roundInfoRefetch();
    }, 10000);
    return () => clearInterval(interval);
  });

  const ethPrice = Number((roundInfo?.[3]?.result as any)?.[1] || 0n) / 1e8;
  const blazePrice =
    (Number((roundInfo?.[2]?.result as any)?.[1] || 0) * ethPrice) /
    Number((roundInfo?.[2]?.result as any)?.[0] || 1);

  const detailCollapseRef = useRef<HTMLInputElement>(null);

  return (
    <>
      <div className="card bg-secondary-bg rounded-3xl overflow-clip border-secondary-light-bg border-4 md:max-w-md w-[300px] md:min-w-[450px] font-outfit">
        <div className="bg-secondary-light-bg text-black px-4 py-2 flex flex-row justify-between items-center text-sm w-full">
          <div>Next Draw</div>
          <div>
            #{currentRound?.toString()} |{" "}
            {format(
              new Date(Number(roundInfo?.[0]?.result?.[3] || 0) * 1000),
              "yyyy-MM-dd HH:mm"
            )}
          </div>
        </div>
        <div className="card-body flex flex-row items-center justify-evenly border-b-2 border-b-gray-400 pb-4">
          <div className="flex flex-col items-center">
            <div className="text-xl whitespace-pre-wrap text-center">
              Prize amount
              {"\n"}
              <span className="text-secondary-light-bg">
                ${" "}
                <span className="underline">
                  {parseFloat(
                    (
                      blazePrice *
                      parseFloat(formatEther(roundInfo?.[4].result?.[2] || 0n))
                    ).toFixed(2)
                  ).toLocaleString()}
                </span>
              </span>
              {/* {"\n"}
              <span className="text-golden/50 text-sm">
                <span className="">
                  {parseFloat(
                    parseFloat(
                      formatEther(roundInfo?.[4].result?.[2] || 0n)
                    ).toFixed(2)
                  ).toLocaleString()}
                </span>{" "}
                BLZE
              </span> */}
            </div>
            <div className="flex flex-row items-center gap-x-4">
              <div>
                <Image src={redStar} alt="RedStar" />
              </div>
              <div className="py-4 whitespace-pre-wrap md:whitespace-normal text-center">
                Tickets Playing:&nbsp;
                <span className="underline">
                  {roundInfo?.[0]?.result?.[1].toLocaleString() || 0}
                </span>
              </div>
              <div>
                <Image src={redStar} alt="RedStar" />
              </div>
            </div>
            {(roundInfo?.[1]?.result?.[2] || 0n) > 0 && (
              <div className="pb-4 whitespace-pre-wrap flex flex-col gap-x-4 items-center">
                <div>View Tickets:</div>
                <button
                  className="btn btn-secondary btn-sm mt-2"
                  onClick={() => setOpenMyTickets(true)}
                >
                  {roundInfo?.[1]?.result?.[2].toLocaleString() || 0}
                  <GrView className="text-green-500" />
                </button>
              </div>
            )}
            <div className="py-4">
              <button
                className={classNames(
                  "btn btn-accent btn-sm text-white",
                  roundIsActive ? "" : "loading loading-spinner"
                )}
                onClick={() => {
                  if (!roundIsActive) return;
                  setOpenBuyTicketModal(true);
                }}
              >
                Buy Tickets
              </button>
            </div>
          </div>
        </div>
        <div className="w-full collapse collapse-arrow">
          <input type="checkbox" ref={detailCollapseRef} />
          <div className="w-full text-center pl-[48px] collapse-title">
            Details
          </div>
          <div className="collapse-content overflow-x-scroll sm:overflow-x-visible">
            <div className="min-h-fit">
              <table className="table font-outfit">
                <thead>
                  <tr>
                    <th>Match</th>
                    <th>Amount SNG</th>
                    <th>Amount USD</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td className="">Match 3</td>
                    <td className="text-right text-sng-red font-bold">
                      {(
                        Number(roundInfo?.[4].result?.[0] || 0n) / 1e18
                      ).toLocaleString()}
                    </td>
                    <td className="text-gray-500 text-right">
                      {parseFloat(
                        (
                          (Number(roundInfo?.[4].result?.[0] || 0n) *
                            blazeData.price) /
                          1e18
                        ).toFixed(2)
                      ).toLocaleString()}
                    </td>
                  </tr>
                  <tr>
                    <td className="">Match 4</td>
                    <td className="text-right text-sng-red font-bold">
                      {(
                        Number(roundInfo?.[4].result?.[1] || 0n) / 1e18
                      ).toLocaleString()}
                    </td>
                    <td className="text-gray-500 text-right">
                      {parseFloat(
                        (
                          (Number(roundInfo?.[4].result?.[1] || 0n) *
                            blazeData.price) /
                          1e18
                        ).toFixed(2)
                      ).toLocaleString()}
                    </td>
                  </tr>
                  <tr>
                    <td className="">Match 5</td>
                    <td className="text-right text-sng-red font-bold">
                      {(
                        Number(roundInfo?.[4].result?.[2] || 0n) / 1e18
                      ).toLocaleString()}
                    </td>
                    <td className="text-gray-500 text-right">
                      {parseFloat(
                        (
                          (Number(roundInfo?.[4].result?.[2] || 0n) *
                            blazeData.price) /
                          1e18
                        ).toFixed(2)
                      ).toLocaleString()}
                    </td>
                  </tr>
                  {/* <tr>
                    <td className="">Burns</td>
                    <td className="text-right text-red-500 font-bold">
                      {(
                        Number(roundInfo?.[4].result?.[3] || 0n) / 1e18
                      ).toLocaleString()}
                    </td>
                    <td className="text-gray-500 text-right">
                      {parseFloat(
                        (
                          (Number(roundInfo?.[4].result?.[3] || 0n) *
                            blazeData.price) /
                          1e18
                        ).toFixed(2)
                      ).toLocaleString()}
                    </td>
                  </tr>
                  <tr>
                    <td className="">Development</td>
                    <td className="text-right text-golden font-bold">
                      {(
                        Number(roundInfo?.[4].result?.[4] || 0n) / 1e18
                      ).toLocaleString()}
                    </td>
                    <td className="text-gray-500 text-right">
                      {parseFloat(
                        (
                          (Number(roundInfo?.[4].result?.[4] || 0n) *
                            blazeData.price) /
                          1e18
                        ).toFixed(2)
                      ).toLocaleString()}
                    </td>
                  </tr> */}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
      <dialog className="modal" open={openMyTickets}>
        <div className="modal-box bg-secondary-bg border-2 border-golden">
          <h4 className="text-2xl font-outfit text-center font-bold pb-6">
            Bought Tickets
          </h4>
          <div className="flex flex-col items-center justify-center gap-3">
            {roundInfo?.[1]?.result?.[0]?.map((ticket, index) => {
              const evenHex = toEvenHexNoPrefix(ticket);
              return (
                <div
                  key={`bought-ticket-index-${index}`}
                  className="flex flex-row items-center justify-center gap-x-2"
                >
                  <div className="text-golden">#{index + 1}</div>
                  {evenHex.match(/..?/g)?.map((hex, ix) => (
                    <TicketNumber
                      key={`bought-ticket-${index}-${ix}`}
                      number={parseInt("0x" + hex, 16)}
                    />
                  ))}
                </div>
              );
            })}
          </div>
        </div>
        <div
          className="modal-backdrop backdrop-blur-sm bg-slate-700/30"
          onClick={() => setOpenMyTickets(false)}
        />
      </dialog>
    </>
  );
};

export default Card;
