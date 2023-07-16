import Image from "next/image";
import { IframeWeb3Button } from "@/components/wagmiComponents/Web3Button";
import jackpotImg from "../../../public/jackpot.png";

const Header = () => {
  return (
    <header className="flex flex-col items-center justify-between py-12 gap-4">
      <Image src={jackpotImg} alt="Jackpot logo" />
      <IframeWeb3Button />
    </header>
  );
};

export default Header;
