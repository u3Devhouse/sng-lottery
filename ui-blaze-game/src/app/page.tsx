import CurrentCard from "@/components/lottery/CurrentCard";
import BuyTicketsModal, {
  TokenData,
} from "@/components/lottery/BuyTicketsModal";
import PastRounds from "@/components/lottery/PastRounds";
import OwnerCard from "@/components/owner/OwnerCard";
import { MobileLink } from "@/components/layout/MobileLink";

import { FaTelegramPlane } from "react-icons/fa";
import { FaYoutube } from "react-icons/fa";
import { FaXTwitter } from "react-icons/fa6";
import { zeroAddress } from "viem";

const Page = async () => {
  const tokenData = await fetch(
    "https://swpfnabsckensdup.swapngo.exchange/jkTydOicF/Y3VycmVdRh?chain=56&&sorder=1",
    {
      headers: {
        "jc-sp-tkn": "1d7-7B8745-09pSfg-hn873",
      },
    }
  ).then((res) => res.json());

  return (
    <>
      <MobileLink />
      <section className="w-full pb4 flex flex-col items-center">
        <h2 className="italic font-outfit pb-4 text-2xl font-bold">
          Current Round
        </h2>
        <CurrentCard />
      </section>
      <section className="flex flex-col items-center py-12">
        <h2 className="italic font-outfit pb-4 text-2xl font-bold">
          Past Rounds
        </h2>
        <PastRounds />
      </section>
      <section className="flex flex-col items-center">
        <OwnerCard />
      </section>
      <section className="flex flex-col items-center">
        <h3 className=" italic text-secondary-light-bg text-2xl pb-6">
          Join Our Community
        </h3>
        <div className="flex flex-row items-center gap-4">
          <SocialLink
            name="Youtube"
            icon={
              <div className="text-red-500 text-4xl p-2 yt-bg">
                <FaYoutube />
              </div>
            }
            link="https://t.me/"
          />
          <SocialLink
            name="Telegram"
            icon={
              <div className="text-white text-xl p-2 bg-blue-400 rounded-full">
                <FaTelegramPlane />
              </div>
            }
            link="https://t.me/"
          />
          <SocialLink
            name="Twitter"
            icon={
              <div className="text-white text-4xl p-2">
                <FaXTwitter />
              </div>
            }
            link="https://t.me/"
          />
        </div>
      </section>
      <BuyTicketsModal
        tokenData={[
          {
            contract: zeroAddress,
            decimals: 18,
            name: "BNB",
            symbol: "BNB",
            image: tokenData.data.find(
              (token: TokenData) => token.symbol === "WBNB"
            )?.image,
          },
          ...tokenData.data,
        ]}
      />
    </>
  );
};

export default Page;

const SocialLink = ({
  icon,
  link,
  name,
}: {
  icon: React.ReactNode;
  link: string;
  name: string;
}) => {
  return (
    <a href={link} target="_blank" rel="noreferrer">
      <div className="flex flex-col items-center gap-2 group">
        <div className="bg-white/5 p-2 rounded-3xl flex flex-col items-center justify-center w-20 h-20 group-hover:bg-white/30">
          {icon}
        </div>
        <p>{name}</p>
      </div>
    </a>
  );
};
