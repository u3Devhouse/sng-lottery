"use client";
import Image from "next/image";
import { useEffect, useState } from "react";
import format from "date-fns/format";
import { useAtom, useSetAtom } from "jotai";
// Contracts
import { useAccount, useContractRead, useContractReads } from "wagmi";
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

const Card = () => {
  const [openMyTickets, setOpenMyTickets] = useState(false);
  const setOpenBuyTicketModal = useSetAtom(openBuyTicketModal);
  const [blazeData, setBlazeInfo] = useAtom(blazeInfo);
  const { address } = useAccount();
  const { data: currentRound, refetch: currentRoundRefetch } = useContractRead({
    address: lotteryContract,
    abi: lotteryAbi,
    functionName: "currentRound",
  });
  const { data: roundInfo, refetch: roundInfoRefetch } = useContractReads({
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
        functionName: "distributionPercentages",
        args: [0n],
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "distributionPercentages",
        args: [1n],
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "distributionPercentages",
        args: [2n],
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "distributionPercentages",
        args: [3n],
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "distributionPercentages",
        args: [4n],
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "distributionPercentages",
        args: [5n],
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "distributionPercentages",
        args: [6n],
      },
    ],
  });

  useEffect(() => {
    setBlazeInfo({
      price:
        (Number(roundInfo?.[2]?.result?.[1] || 0) *
          (Number(roundInfo?.[3]?.result?.[1] || 0n) / 1e8)) /
        Number(roundInfo?.[2]?.result?.[0] || 1),
      ticketPrice: Number(formatEther(roundInfo?.[0]?.result?.[2] || 0n)),
      currentRound: Number(currentRound?.toString() || 0),
    });
  }, [setBlazeInfo, roundInfo, currentRound]);

  useEffect(() => {
    const interval = setInterval(() => {
      void currentRoundRefetch();
      void roundInfoRefetch();
    }, 10000);
    return () => clearInterval(interval);
  });

  console.log(roundInfo);

  const ethPrice = Number(roundInfo?.[3]?.result?.[1] || 0n) / 1e8;
  const blazePrice =
    (Number(roundInfo?.[2]?.result?.[1] || 0) * ethPrice) /
    Number(roundInfo?.[2]?.result?.[0] || 1);

  console.log({
    ethPrice,
    blazePrice,
  });
  return (
    <>
      <div className="card bg-secondary-bg rounded-3xl overflow-hidden border-golden border-4 max-w-md font-outfit">
        <div className="bg-golden text-black px-4 py-2 flex flex-row justify-between items-center text-sm">
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
          <div className="w-16">
            <Image src={flyingTokens} alt="Flying tokens" />
          </div>
          <div className="flex flex-col items-center">
            <div className="text-xl whitespace-pre-wrap md:whitespace-normal text-center">
              Prize amount:{" \n"}
              <span className="text-golden">
                ${" "}
                <span className="underline">
                  {(
                    blazePrice *
                    Number(formatEther(roundInfo?.[0]?.result?.[0] || 0n))
                  ).toLocaleString()}
                </span>
              </span>
            </div>
            <div className="py-4 whitespace-pre-wrap md:whitespace-normal text-center">
              Tickets playing:{" \n"}
              <span className="underline">
                {roundInfo?.[0]?.result?.[1].toLocaleString() || 0}
              </span>
            </div>
            {(roundInfo?.[1]?.result?.[2] || 0n) > 0 && (
              <div className="pb-4">
                Your Tickets:{" "}
                <button
                  className="underline"
                  onClick={() => setOpenMyTickets(true)}
                >
                  {roundInfo?.[1]?.result?.[2].toLocaleString() || 0}
                </button>
              </div>
            )}
            <div className="py-4">
              <button
                className="btn btn-accent btn-sm text-white"
                onClick={() => setOpenBuyTicketModal(true)}
              >
                Buy Tickets
              </button>
            </div>
          </div>
          <div className="w-16">
            <Image src={flyingTokens} alt="Flying tokens" />
          </div>
        </div>
        <div className="w-full collapse collapse-arrow">
          <input type="checkbox" />
          <div className="w-full flex flex-row items-center justify-center gap-x-2 collapse-title">
            Details
          </div>
          <div className="collapse-content">
            <table className="table font-outfit">
              <thead>
                <tr>
                  <th>Match</th>
                  <th>Amount BLZE</th>
                  <th>Amount USD</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td className="">Match 1</td>
                  <td className="text-right text-golden font-bold">
                    {Number(
                      (roundInfo?.[0].result?.[0] || 0n) *
                        (roundInfo?.[4]?.result || 0n)
                    ) / 100e18}
                  </td>
                  <td className="text-gray-500 text-right">
                    {(
                      (Number(
                        (roundInfo?.[0].result?.[0] || 0n) *
                          (roundInfo?.[4]?.result || 0n)
                      ) *
                        blazeData.price) /
                      100e18
                    ).toFixed(4)}
                  </td>
                </tr>
                <tr>
                  <td className="">Match 2</td>
                  <td className="text-right text-golden font-bold">
                    {Number(
                      (roundInfo?.[0].result?.[0] || 0n) *
                        (roundInfo?.[5]?.result || 0n)
                    ) / 100e18}
                  </td>
                  <td className="text-gray-500 text-right">
                    {(
                      (Number(
                        (roundInfo?.[0].result?.[0] || 0n) *
                          (roundInfo?.[5]?.result || 0n)
                      ) *
                        blazeData.price) /
                      100e18
                    ).toFixed(4)}
                  </td>
                </tr>
                <tr>
                  <td className="">Match 3</td>
                  <td className="text-right text-golden font-bold">
                    {Number(
                      (roundInfo?.[0].result?.[0] || 0n) *
                        (roundInfo?.[6]?.result || 0n)
                    ) / 100e18}
                  </td>
                  <td className="text-gray-500 text-right">
                    {(
                      (Number(
                        (roundInfo?.[0].result?.[0] || 0n) *
                          (roundInfo?.[6]?.result || 0n)
                      ) *
                        blazeData.price) /
                      100e18
                    ).toFixed(4)}
                  </td>
                </tr>
                <tr>
                  <td className="">Match 4</td>
                  <td className="text-right text-golden font-bold">
                    {Number(
                      (roundInfo?.[0].result?.[0] || 0n) *
                        (roundInfo?.[7]?.result || 0n)
                    ) / 100e18}
                  </td>
                  <td className="text-gray-500 text-right">
                    {(
                      (Number(
                        (roundInfo?.[0].result?.[0] || 0n) *
                          (roundInfo?.[7]?.result || 0n)
                      ) *
                        blazeData.price) /
                      100e18
                    ).toFixed(4)}
                  </td>
                </tr>
                <tr>
                  <td className="">Match 5</td>
                  <td className="text-right text-golden font-bold">
                    {Number(
                      (roundInfo?.[0].result?.[0] || 0n) *
                        (roundInfo?.[8]?.result || 0n)
                    ) / 100e18}
                  </td>
                  <td className="text-gray-500 text-right">
                    {(
                      (Number(
                        (roundInfo?.[0].result?.[0] || 0n) *
                          (roundInfo?.[8]?.result || 0n)
                      ) *
                        blazeData.price) /
                      100e18
                    ).toFixed(4)}
                  </td>
                </tr>
                <tr>
                  <td className="">Burn</td>
                  <td className="text-right text-golden font-bold">
                    {Number(
                      (roundInfo?.[0].result?.[0] || 0n) *
                        (roundInfo?.[9]?.result || 0n)
                    ) / 100e18}
                  </td>
                  <td className="text-gray-500 text-right">
                    {(
                      (Number(
                        (roundInfo?.[0].result?.[0] || 0n) *
                          (roundInfo?.[9]?.result || 0n)
                      ) *
                        blazeData.price) /
                      100e18
                    ).toFixed(4)}
                  </td>
                </tr>
                <tr>
                  <td className="">Team</td>
                  <td className="text-right text-golden font-bold">
                    {Number(
                      (roundInfo?.[0].result?.[0] || 0n) *
                        (roundInfo?.[10]?.result || 0n)
                    ) / 100e18}
                  </td>
                  <td className="text-gray-500 text-right">
                    {(
                      (Number(
                        (roundInfo?.[0].result?.[0] || 0n) *
                          (roundInfo?.[10]?.result || 0n)
                      ) *
                        blazeData.price) /
                      100e18
                    ).toFixed(4)}
                  </td>
                </tr>
              </tbody>
            </table>
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
              const hexNum = toHex(ticket).replace("0x", "");
              const evenHex = hexNum.length % 2 === 0 ? hexNum : "0" + hexNum;
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
