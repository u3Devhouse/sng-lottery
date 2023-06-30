"use client";
import { blazeInfo } from "@/data/atoms";
import { lotteryAbi, lotteryContract } from "@/data/contracts";
import classNames from "classnames";
import { useAtomValue } from "jotai";
import { useEffect, useState } from "react";
import {
  BsChevronBarLeft,
  BsChevronLeft,
  BsChevronRight,
  BsChevronBarRight,
} from "react-icons/bs";
import { formatEther, zeroAddress } from "viem";
import {
  useAccount,
  useContractInfiniteReads,
  useContractRead,
  useContractReads,
} from "wagmi";

const PastRounds = () => {
  const { address } = useAccount();
  const blazeLott = useAtomValue(blazeInfo);
  const [selectedRound, setSelectedRound] = useState(
    blazeLott.currentRound - 1
  );

  const { data } = useContractRead({
    address: lotteryContract,
    abi: lotteryAbi,
    functionName: "roundInfo",
    args: [BigInt(selectedRound || 0)],
  });

  const { data: matchesInfo } = useContractReads({
    contracts: [
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "matches",
        args: [data?.[4] || 0n],
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
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "getUserTickets",
        args: [address || zeroAddress, BigInt(selectedRound)],
      },
    ],
  });

  const maxPrev = blazeLott.currentRound - 1;

  useEffect(() => {
    setSelectedRound(blazeLott.currentRound - 1);
  }, [blazeLott.currentRound, setSelectedRound]);
  // if (prevRound == 0)
  //   return (
  //     <div className="text-gray-500 font-outfit font-bold py-12">
  //       Pending Rounds
  //     </div>
  //   );
  return (
    <div className="card bg-secondary-bg rounded-3xl overflow-hidden border-golden-dark border-4 md:max-w-md w-[300px] md:min-w-[450px] font-outfit">
      <div className="bg-golden-dark w-full px-4 py-2 flex flex-row justify-between items-center text-sm">
        <div>#{selectedRound}</div>
        <div className="flex flex-row items-center">
          <button
            className={classNames(
              "btn btn-circle btn-sm btn-primary",
              selectedRound == 0 && "btn-disabled"
            )}
          >
            <BsChevronBarLeft />
          </button>
          <button
            className={classNames(
              "btn btn-circle btn-sm btn-primary",
              selectedRound == 0 && "btn-disabled"
            )}
          >
            <BsChevronLeft />
          </button>
          <button
            className={classNames(
              "btn btn-circle btn-sm btn-primary",
              selectedRound >= maxPrev && "btn-disabled"
            )}
          >
            <BsChevronRight />
          </button>
          <button
            className={classNames(
              "btn btn-circle btn-sm btn-primary",
              selectedRound >= maxPrev && "btn-disabled"
            )}
          >
            <BsChevronBarRight />
          </button>
        </div>
      </div>
      <div className="card-body">
        <h4 className="text-center whitespace-pre-wrap">
          Round Pot:{"\n"}
          <span className="text-golden font-bold text-xl">
            {parseFloat(formatEther(data?.[0] || 0n)).toLocaleString()} BLZE
          </span>
        </h4>
        <div className="text-center">
          Your Tickets:{" "}
          {Number(matchesInfo?.[8]?.result?.[2] || 0n).toLocaleString()}
        </div>
      </div>
      <div className="w-full collapse collapse-arrow">
        <input type="checkbox" />
        <div className="w-full flex flex-row items-center justify-center gap-x-2 collapse-title">
          Details
        </div>
        <div className="collapse-content overflow-auto">
          <table className="table font-outfit">
            <thead>
              <tr>
                <th>Match</th>
                <th className="text-center">Matches</th>
                <th className="text-right">BLZE</th>
              </tr>
            </thead>
            <tbody>
              {/* <tr>
                <td className="text-sm">Match 1</td>
                <td className="text-center text-golden font-bold">
                  {Number(matchesInfo?.[0]?.result?.[0] || 0n).toLocaleString()}
                </td>
                <td className="text-gray-500 text-right">
                  {(
                    Number(
                      (data?.[0] || 0n) * (matchesInfo?.[1]?.result || 0n)
                    ) / 100e18
                  ).toLocaleString()}
                </td>
              </tr>
              <tr>
                <td className="text-sm">Match 2</td>
                <td className="text-center text-golden font-bold">
                  {Number(matchesInfo?.[0]?.result?.[1] || 0n).toLocaleString()}
                </td>
                <td className="text-gray-500 text-right">
                  {(
                    Number(
                      (data?.[0] || 0n) * (matchesInfo?.[2]?.result || 0n)
                    ) / 100e18
                  ).toLocaleString()}
                </td>
              </tr> */}
              <tr>
                <td className="text-sm">Match 3</td>
                <td className="text-center text-golden font-bold">
                  {Number(matchesInfo?.[0]?.result?.[2] || 0n).toLocaleString()}
                </td>
                <td className="text-gray-500 text-right">
                  {(
                    Number(
                      (data?.[0] || 0n) * (matchesInfo?.[3]?.result || 0n)
                    ) / 100e18
                  ).toLocaleString()}
                </td>
              </tr>
              <tr>
                <td className="text-sm">Match 4</td>
                <td className="text-center text-golden font-bold">
                  {Number(matchesInfo?.[0]?.result?.[3] || 0n).toLocaleString()}
                </td>
                <td className="text-gray-500 text-right">
                  {(
                    Number(
                      (data?.[0] || 0n) * (matchesInfo?.[4]?.result || 0n)
                    ) / 100e18
                  ).toLocaleString()}
                </td>
              </tr>
              <tr>
                <td className="text-sm">Match 5</td>
                <td className="text-center text-golden font-bold">
                  {Number(matchesInfo?.[0]?.result?.[4] || 0n).toLocaleString()}
                </td>
                <td className="text-gray-500 text-right">
                  {(
                    Number(
                      (data?.[0] || 0n) * (matchesInfo?.[5]?.result || 0n)
                    ) / 100e18
                  ).toLocaleString()}
                </td>
              </tr>
              <tr>
                <td className="">Burn</td>
                <td className="text-golden text-right" colSpan={2}>
                  {(
                    Number(
                      (data?.[0] || 0n) * (matchesInfo?.[5]?.result || 0n)
                    ) / 100e18
                  ).toLocaleString()}
                  &nbsp;BLZE
                </td>
              </tr>
              <tr>
                <td className="">Development</td>
                <td className="text-golden text-right" colSpan={2}>
                  {(
                    Number(
                      (data?.[0] || 0n) * (matchesInfo?.[6]?.result || 0n)
                    ) / 100e18
                  ).toLocaleString()}
                  &nbsp;BLZE
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
export default PastRounds;
