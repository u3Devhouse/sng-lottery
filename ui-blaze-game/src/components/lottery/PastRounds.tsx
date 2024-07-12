"use client";
import { blazeInfo } from "@/data/atoms";
import { lotteryAbi, lotteryContract } from "@/data/contracts";
import { toEvenHexNoPrefix } from "@/utils/stringify";
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
  useContractRead,
  useContractReads,
  useWriteContract,
} from "wagmi";
import TicketNumber from "./TicketNumber";
import { GrView } from "react-icons/gr";

// const address = "";

const PastRounds = () => {
  const { address } = useAccount();
  const blazeLott = useAtomValue(blazeInfo);
  const [openMyTickets, setOpenMyTickets] = useState(false);
  const [selectedRound, setSelectedRound] = useState(
    blazeLott.currentRound > 1 ? blazeLott.currentRound - 1 : 0
  );

  const { data } = useContractRead({
    address: lotteryContract,
    abi: lotteryAbi,
    functionName: "roundInfo",
    args: [BigInt(selectedRound || 0)],
  });

  const { data: matchesInfo, refetch: matchRefetch } = useContractReads({
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
        functionName: "roundDistribution",
        args: [BigInt(selectedRound) || 0n],
      },
      {
        address: lotteryContract,
        abi: lotteryAbi,
        functionName: "getUserTickets",
        args: [address || zeroAddress, BigInt(selectedRound)],
      },
    ],
  });

  const userTickets = Number(
    matchesInfo?.[2]?.result?.[2] || 0n
  ).toLocaleString();

  const userClaims = matchesInfo?.[2]?.result?.[1].filter((x) => x) || [];
  const userWinners =
    matchesInfo?.[2]?.result?.[0]
      ?.map((ticket, index) => {
        const hexTicketNumbers = toEvenHexNoPrefix(ticket).match(/..?/g) || [];
        const winnerTicketNumbers =
          toEvenHexNoPrefix(matchesInfo?.[0]?.result?.[6] || 0n).match(
            /..?/g
          ) || [];
        let matches = 0;
        let matchIndexes = [];
        // check that hexTicketNumbers exist in winnerTicketNumbers but not in the same index
        for (let i = 0; i < hexTicketNumbers.length; i++) {
          for (let j = 0; j < winnerTicketNumbers.length; j++) {
            if (
              hexTicketNumbers[i] == winnerTicketNumbers[j] &&
              matchIndexes.indexOf(j) == -1
            ) {
              matches++;
              matchIndexes.push(j);
              break;
            }
          }
        }
        return { matches, index };
      })
      .filter((match) => match.matches > 2) || [];

  const { data: toClaimInfo } = useContractRead({
    address: lotteryContract,
    abi: lotteryAbi,
    functionName: "checkTickets",
    args: [
      BigInt(selectedRound),
      userWinners.map((winner) => BigInt(winner.index)),
      address || zeroAddress,
    ],
  });

  const maxPrev = blazeLott.currentRound - 1;

  useEffect(() => {
    setSelectedRound(() =>
      blazeLott.currentRound > 1 ? blazeLott.currentRound - 1 : 0
    );
  }, [blazeLott.currentRound, setSelectedRound]);

  const { writeContract, isPending, isSuccess } = useWriteContract();

  if (blazeLott.currentRound < 2)
    return (
      <div className="text-gray-500 font-outfit font-bold py-12">
        Pending Rounds
      </div>
    );
  return (
    <>
      <div className="card bg-secondary-bg rounded-3xl overflow-hidden border-golden-dark border-4 md:max-w-md w-[300px] md:min-w-[450px] font-outfit">
        <div className="bg-golden w-full px-4 py-2 flex flex-row justify-between items-center text-sm text-black">
          <div>#{selectedRound}</div>
          <div className="flex flex-row items-center">
            <button
              className={classNames(
                "btn btn-circle btn-sm bg-golden text-black border-0 hover:bg-golden-dark",
                selectedRound < 2 && "btn-disabled"
              )}
              onClick={() => {
                if (selectedRound > 1) setSelectedRound(1);
              }}
            >
              <BsChevronBarLeft />
            </button>
            <button
              className={classNames(
                "btn btn-circle btn-sm bg-golden text-black border-0 hover:bg-golden-dark",
                selectedRound < 2 && "btn-disabled"
              )}
              onClick={() => {
                if (selectedRound > 1) setSelectedRound((r) => r - 1);
              }}
            >
              <BsChevronLeft />
            </button>
            <button
              className={classNames(
                "btn btn-circle btn-sm bg-golden text-black border-0 hover:bg-golden-dark",
                selectedRound >= maxPrev && "btn-disabled"
              )}
              onClick={() => {
                if (selectedRound < blazeLott.currentRound - 1)
                  setSelectedRound((r) => r + 1);
              }}
            >
              <BsChevronRight />
            </button>
            <button
              className={classNames(
                "btn btn-circle btn-sm bg-golden text-black border-0 hover:bg-golden-dark",
                selectedRound >= maxPrev && "btn-disabled"
              )}
              onClick={() => {
                if (selectedRound < blazeLott.currentRound - 1)
                  setSelectedRound(blazeLott.currentRound - 1);
              }}
            >
              <BsChevronBarRight />
            </button>
          </div>
        </div>
        <div className="card-body border-b-2 border-slate-500">
          <h4 className="text-center whitespace-pre-wrap">
            Round Pot:{"\n"}
            <span className="text-golden font-bold text-xl">
              {parseFloat(formatEther(data?.[0] || 0n)).toLocaleString()} BLZE
            </span>
          </h4>
          <div className="flex flex-row items-center justify-center gap-x-4">
            <div>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="50"
                height="16"
                viewBox="0 0 50 16"
                fill="none"
              >
                <line
                  x1="50"
                  y1="15"
                  x2="19.1489"
                  y2="15"
                  stroke="#E0B654"
                  strokeWidth="2"
                />
                <line
                  x1="50"
                  y1="1"
                  x2="19.1489"
                  y2="1"
                  stroke="#E0B654"
                  strokeWidth="2"
                />
                <line x1="50" y1="8" y2="8" stroke="#E0B654" strokeWidth="2" />
              </svg>
            </div>
            <div className="flex flex-col justify-center">
              <div className="text-center">
                Your Tickets:&nbsp;
                <button
                  className={classNames(
                    "btn btn-secondary btn-sm mt-2",
                    parseInt(userTickets) == 0 && "btn-disabled "
                  )}
                  onClick={() => {
                    parseInt(userTickets) > 0 && setOpenMyTickets(true);
                  }}
                >
                  {userTickets}
                  <GrView className="text-green-500" />
                </button>
              </div>
              <div className="text-center">
                Your Winners: {userWinners?.length || 0}
              </div>
            </div>
            <div>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="50"
                height="16"
                viewBox="0 0 50 16"
                fill="none"
              >
                <line
                  y1="1"
                  x2="30.8511"
                  y2="1"
                  stroke="#E0B654"
                  strokeWidth="2"
                />
                <line
                  y1="15"
                  x2="30.8511"
                  y2="15"
                  stroke="#E0B654"
                  strokeWidth="2"
                />
                <line y1="8" x2="50" y2="8" stroke="#E0B654" strokeWidth="2" />
              </svg>
            </div>
          </div>
          {userWinners.length > 0 && (
            <div className="text-center">
              Your Claims: {userClaims.length || 0}
            </div>
          )}
          {(toClaimInfo || 0n) > 0n && (
            <div className="text-center">
              To Claim:{" "}
              {parseFloat(formatEther(toClaimInfo || 0n)).toLocaleString()}
            </div>
          )}
          <div>
            <div className="text-sm text-golden pb-4">Winner Number</div>
            <div className="flex flex-row items-center justify-center gap-x-2">
              {toEvenHexNoPrefix(matchesInfo?.[0]?.result?.[6] || 0n)
                .match(/..?/g)
                ?.map((hex, ix) => (
                  <TicketNumber
                    key={`bought-ticket-winner-${ix}`}
                    number={parseInt("0x" + hex, 16)}
                  />
                ))}
            </div>
          </div>
          {userWinners.length > 0 && userWinners.length > userClaims.length && (
            <>
              <button
                className={classNames(
                  "btn btn-secondary mt-2",
                  isPending ? "loading loading-spinner text-golden mx-auto" : ""
                )}
                disabled={isPending || userWinners.length == 0}
                onClick={() =>
                  writeContract(
                    {
                      address: lotteryContract,
                      abi: lotteryAbi,
                      functionName: "claimTickets",
                      args: [
                        BigInt(selectedRound),
                        userWinners.map((winner) => BigInt(winner.index)),
                        userWinners.map((winner) => winner.matches),
                      ],
                    },
                    {
                      onSuccess: () => {
                        matchRefetch();
                      },
                    }
                  )
                }
              >
                Claim Wins
              </button>
              {isSuccess && (
                <div className="text-green-400 text-center">
                  Claimed Winnings!
                </div>
              )}
            </>
          )}
        </div>
        <div className="w-full collapse collapse-arrow">
          <input type="checkbox" />
          <div className="w-full text-center pl-[48px] collapse-title">
            Details
          </div>
          <div className="collapse-content overflow-x-scroll sm:overflow-x-visible">
            <div className="min-h-fit">
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
                    {Number(
                      matchesInfo?.[0]?.result?.[0] || 0n
                    ).toLocaleString()}
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
                    {Number(
                      matchesInfo?.[0]?.result?.[1] || 0n
                    ).toLocaleString()}
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
                      {Number(
                        matchesInfo?.[0]?.result?.[2] || 0n
                      ).toLocaleString()}
                    </td>
                    <td className="text-gray-500 text-right">
                      {(
                        Number(matchesInfo?.[1]?.result?.[0] || 0n) / 1e18
                      ).toLocaleString()}
                    </td>
                  </tr>
                  <tr>
                    <td className="text-sm">Match 4</td>
                    <td className="text-center text-golden font-bold">
                      {Number(
                        matchesInfo?.[0]?.result?.[3] || 0n
                      ).toLocaleString()}
                    </td>
                    <td className="text-gray-500 text-right">
                      {(
                        Number(matchesInfo?.[1]?.result?.[1] || 0n) / 1e18
                      ).toLocaleString()}
                    </td>
                  </tr>
                  <tr>
                    <td className="text-sm">Match 5</td>
                    <td className="text-center text-golden font-bold">
                      {Number(
                        matchesInfo?.[0]?.result?.[4] || 0n
                      ).toLocaleString()}
                    </td>
                    <td className="text-gray-500 text-right">
                      {(
                        Number(matchesInfo?.[1]?.result?.[2] || 0n) / 1e18
                      ).toLocaleString()}
                    </td>
                  </tr>
                  {/* <tr>
                    <td className="">Burn</td>
                    <td className="text-red-500 text-right" colSpan={2}>
                      {(
                        Number(matchesInfo?.[1]?.result?.[3] || 0n) / 1e18
                      ).toLocaleString()}
                      &nbsp;BLZE
                    </td>
                  </tr>
                  <tr>
                    <td className="">Development</td>
                    <td className="text-golden text-right" colSpan={2}>
                      {(
                        Number(matchesInfo?.[1]?.result?.[4] || 0n) / 1e18
                      ).toLocaleString()}
                      &nbsp;BLZE
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
          <div className="bg-emerald-700 pb-4 pt-2 rounded-full sticky top-0">
            <div className="text-sm text-center text-golden pb-2">
              Round Winner Number
            </div>
            <div className="flex flex-row items-center justify-center gap-x-2">
              <div className="font-normal">W#</div>
              {toEvenHexNoPrefix(matchesInfo?.[0]?.result?.[6] || 0n)
                .match(/..?/g)
                ?.map((hex, ix) => (
                  <TicketNumber
                    key={`bought-ticket-winner-${ix}`}
                    number={parseInt("0x" + hex, 16)}
                  />
                ))}
            </div>
          </div>
          <div className="flex flex-col items-center justify-center">
            {matchesInfo?.[2]?.result?.[0]?.map((ticket, index) => {
              const hexNum = toEvenHexNoPrefix(ticket);
              const winnerInfo = userWinners.filter((x) => x.index === index);
              const isWinner = winnerInfo.length > 0;
              const matches = winnerInfo[0]?.matches || 0;
              return (
                <div
                  key={`bought-ticket-index-${index}`}
                  className={classNames(
                    "flex flex-row items-center justify-center gap-x-2 py-2 px-2 rounded-full",
                    isWinner ? "bg-green-400/80" : ""
                  )}
                >
                  <div
                    className={classNames(
                      isWinner ? "text-black font-bold" : "text-golden",
                      "whitespace-pre-wrap text-center"
                    )}
                  >
                    #{index + 1}
                    {isWinner ? `\n(${matches})` : ""}
                  </div>
                  {hexNum.match(/..?/g)?.map((hex, ix) => (
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
export default PastRounds;
