"use client";
import Image from "next/image";
import { FaChevronDown } from "react-icons/fa";
// Images
import flyingTokens from "@/../public/assets/flying_tokens.png";
const round = 1;
const Card = () => {
  return (
    <div className="card bg-secondary-bg rounded-3xl overflow-hidden border-golden border-4 max-w-md font-outfit">
      <div className="bg-golden text-black px-4 py-2 flex flex-row justify-between items-center text-sm">
        <div>Next Draw</div>
        <div>#{round} | 2023-07-15 10:00</div>
      </div>
      <div className="card-body flex flex-row items-center justify-evenly border-b-2 border-b-gray-400 pb-4">
        <div className="w-16">
          <Image src={flyingTokens} alt="Flying tokens" />
        </div>
        <div className="flex flex-col items-center">
          <div className="text-xl">
            Prize amount:{" "}
            <span className="text-golden">
              $ <span className="underline">1,000</span>
            </span>
          </div>
          <div className="py-4">
            Tickets playing: <span className="underline">1,000</span>
          </div>
          <div className="py-4">
            <button className="btn btn-accent btn-sm text-white">
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
        <div className="collapse-content">content here</div>
      </div>
    </div>
  );
};

export default Card;
