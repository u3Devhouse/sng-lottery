"use client";

import { blazeInfo } from "@/data/atoms";
import { lotteryAbi, lotteryContract } from "@/data/contracts";
import classNames from "classnames";
import { useAtomValue } from "jotai";
import { useState } from "react";
import { useAccount, useWriteContract } from "wagmi";

import intervalToDuration from "date-fns/intervalToDuration";
import formatDuration from "date-fns/formatDuration";
import { BaseError, isAddress } from "viem";

const owner = "0x28b170c9B73603E09bF51B485252218A68E279D2";

const OwnerCard = () => {
  const { address } = useAccount();
  const mainInfo = useAtomValue(blazeInfo);
  const [initPrice, setInitPrice] = useState<string>("");
  const [initEnd, setInitEnd] = useState<number>(0);
  const [duration, setDuration] = useState<number>(0);
  const [potAdd, setPotAdd] = useState<number>(0);
  const [newUpkeeper, setNewUpkeeper] = useState<string>("");
  const [isUpkeeper, setIsUpkeeper] = useState<boolean>(false);
  const selectedInitPrice = isNaN(parseFloat(initPrice))
    ? 0
    : parseFloat(initPrice);

  const { writeContract, isPending, isError, error } = useWriteContract();

  const dateDuration = {
    base: new Date(),
    nextDate: new Date(new Date().getTime() + (duration || 0) * 1000),
  };

  if (!address || address !== owner) return null;
  return (
    <div className="card border-golden border-2 bg-secondary-bg">
      <div className="card-body">
        <h4 className="card-title">Owner Panel</h4>
        {mainInfo.currentRound < 1 && (
          <div className="flex flex-col items-center">
            <h5 className="font-bold">
              Activate Lottery (only when round &lt;1)
            </h5>
            <div className="form-control w-full">
              <label className="label">
                <span className="label-text text-golden">
                  Initial Price (BLZE)
                </span>
              </label>
              <input
                type="number"
                value={initPrice}
                onChange={(e) =>
                  setInitPrice(e.target.valueAsNumber.toString())
                }
                className="input input-primary bg-secondary-bg border-2"
                placeholder="Initial Price in BLZE"
              />
              <label className="label">
                <span className="label-text-alt">
                  Price:{" "}
                  {parseFloat(
                    (mainInfo.price * selectedInitPrice).toLocaleString()
                  ).toFixed(4)}{" "}
                  USD
                </span>
              </label>
            </div>
            <div className="form-control w-full">
              <label className="label">
                <span className="label-text text-golden">First Round End</span>
              </label>
              <input
                type="datetime-local"
                onChange={(e) => {
                  setInitEnd(e.target.valueAsNumber);
                }}
                className="input input-primary bg-secondary-bg border-2"
                placeholder="End of First Round"
              />
            </div>
            <button
              className={classNames(
                "btn btn-secondary my-2",
                isPending ? "loading loading-spinner" : ""
              )}
              onClick={() => {
                if (isPending) return;
                writeContract({
                  address: lotteryContract,
                  abi: lotteryAbi,
                  functionName: "activateLottery",
                  args: [
                    BigInt(initPrice || 0) * BigInt(10 ** 18),
                    BigInt(initEnd / 1000),
                  ],
                });
              }}
            >
              Activate
            </button>
          </div>
        )}
        <div className="flex flex-col items-center">
          <h5 className="font-bold w-full">Set Duration For Next Rounds</h5>
          <div className="form-control w-full">
            <label className="label">
              <span className="label-text text-golden">
                Duration In Seconds
              </span>
            </label>
            <input
              type="number"
              value={duration}
              onChange={(e) => {
                setDuration(e.target.valueAsNumber);
              }}
              className="input input-primary bg-secondary-bg border-2"
              placeholder="Round Duration in Seconds"
              onClick={(e) => e.currentTarget.select()}
            />
            <label className="label">
              <span className="label-text-alt">
                Duration:{" "}
                {formatDuration(
                  intervalToDuration({
                    start: dateDuration.base,
                    end: dateDuration.nextDate,
                  })
                )}
              </span>
            </label>
          </div>
          <button
            className={classNames(
              "btn btn-secondary my-2",
              isPending ? "loading loading-spinner" : ""
            )}
            onClick={() => {
              if (isPending) return;
              writeContract({
                address: lotteryContract,
                abi: lotteryAbi,
                functionName: "setRoundDuration",
                args: [BigInt(duration || 3600)],
              });
            }}
          >
            Set Duration
          </button>
        </div>
        <div className="flex flex-col items-center">
          <h5 className="font-bold w-full">Add BLZE to Pot</h5>
          <div className="form-control w-full">
            <label className="label">
              <span className="label-text text-golden">BLZE to Add</span>
            </label>
            <input
              type="number"
              value={potAdd}
              onChange={(e) => {
                setPotAdd(e.target.valueAsNumber);
              }}
              className="input input-primary bg-secondary-bg border-2"
              placeholder="BLZE to Add"
              onClick={(e) => e.currentTarget.select()}
            />
            <label className="label">
              <span className="label-text-alt">
                USD:&nbsp;{potAdd * mainInfo.price}
              </span>
            </label>
            {isError && <div>{(error as BaseError)?.shortMessage}</div>}
          </div>
          <button
            className={classNames(
              "btn btn-secondary my-2",
              isPending ? "loading loading-spinner" : ""
            )}
            onClick={() => {
              if (isPending) return;
              writeContract({
                address: lotteryContract,
                abi: lotteryAbi,
                functionName: "addToPot",
                args: [
                  BigInt(potAdd || 0) * BigInt(10 ** 18),
                  BigInt(mainInfo.currentRound > 0 ? mainInfo.currentRound : 1),
                  [25n, 25n, 25n],
                ],
              });
            }}
          >
            Add To Pot
          </button>
        </div>
        <div className="flex flex-col items-center">
          <h5 className="font-bold w-full">Set Upkeeper</h5>
          <div className="form-control w-full">
            <label className="label">
              <span className="label-text text-golden">Upkeeper Address</span>
            </label>
            <input
              type="text"
              value={newUpkeeper}
              onChange={(e) => {
                setNewUpkeeper(e.target.value);
              }}
              className={classNames(
                "input input-primary bg-secondary-bg border-2",
                isAddress(newUpkeeper) ? "border-green-500" : "border-red-500"
              )}
              placeholder="Upkeeper Address to Edit"
              onClick={(e) => e.currentTarget.select()}
            />
            <label className="label">
              <span className="label-text-alt">Is Upkeeper</span>
              <input
                type="checkbox"
                checked={isUpkeeper}
                onChange={(e) => setIsUpkeeper(e.target.checked)}
                className="checkbox checkbox-primary"
                onClick={(e) => e.currentTarget.select()}
              />
            </label>
          </div>
          <button
            className={classNames(
              "btn btn-secondary my-2",
              isPending ? "loading loading-spinner" : ""
            )}
            onClick={() => {
              if (isPending) return;
              writeContract({
                address: lotteryContract,
                abi: lotteryAbi,
                functionName: "setUpkeeper",
                args: [newUpkeeper as `0x{string}`, isUpkeeper],
              });
            }}
          >
            Set Upkeeper
          </button>
        </div>
        <div className="flex flex-col items-center">
          <h5 className="font-bold w-full">Set Price</h5>
          <div className="form-control w-full">
            <label className="label">
              <span className="label-text text-golden">
                Price For round {mainInfo.currentRound + 1}
              </span>
            </label>
            <input
              type="number"
              value={initPrice}
              onChange={(e) => setInitPrice(e.target.valueAsNumber.toString())}
              className="input input-primary bg-secondary-bg border-2"
              placeholder="New Price in BLZE"
            />
            <label className="label">
              <span className="label-text-alt">
                Price:{" "}
                {parseFloat(
                  (mainInfo.price * selectedInitPrice).toLocaleString()
                ).toFixed(4)}{" "}
                USD
              </span>
            </label>
          </div>
          <button
            className={classNames(
              "btn btn-secondary my-2",
              isPending ? "loading loading-spinner" : ""
            )}
            onClick={() => {
              if (isPending) return;
              writeContract({
                address: lotteryContract,
                abi: lotteryAbi,
                functionName: "setCurrencyPrice",
                args: [
                  BigInt(initPrice || 0) * BigInt(10 ** 18),
                  BigInt(mainInfo.currentRound + 1),
                ],
              });
            }}
          >
            Set Price
          </button>
        </div>
        <div className="flex flex-col items-center">
          <h5 className="font-bold w-full">End Current Round</h5>
          <button
            className={classNames(
              "btn btn-secondary my-2",
              isPending ? "loading loading-spinner" : ""
            )}
            onClick={() => {
              if (isPending) return;
              writeContract({
                address: lotteryContract,
                abi: lotteryAbi,
                functionName: "endRound",
              });
            }}
          >
            End Current Round
          </button>
        </div>
      </div>
    </div>
  );
};

export default OwnerCard;
