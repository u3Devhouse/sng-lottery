import Image from "next/image";
import { Web3Button } from "@/components/wagmiComponents/Web3Button";
import jackpotImg from "../../../public/jackpot.png";
import classNames from "classnames";

const Header = () => {
  const isIframe = typeof window !== "undefined" && window !== window.top;
  return (
    <header className="flex flex-col items-center justify-between py-12 gap-4">
      <Image src={jackpotImg} alt="Jackpot logo" />
      <div className={classNames("pt-4", isIframe && "hidden")}>
        <Web3Button />
      </div>
    </header>
  );
};

export default Header;
