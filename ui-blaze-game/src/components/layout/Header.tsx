import Image from "next/image";
import { IframeWeb3Button } from "@/components/wagmiComponents/Web3Button";
import jackpotImg from "@/../public/assets/SNG Jackpot 1.svg";

const Header = () => {
  return (
    <header className="flex flex-col items-center justify-between py-12 gap-4 border-t-2 border-[#E30613]">
      <Image src={jackpotImg} alt="Jackpot logo" />
      <IframeWeb3Button />
    </header>
  );
};

export default Header;
