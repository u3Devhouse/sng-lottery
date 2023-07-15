import Link from "next/link";
import Image from "next/image";
import { TiSocialFacebook, TiSocialTwitter } from "react-icons/ti";
import { GrInstagram } from "react-icons/gr";
import { RiMessengerFill } from "react-icons/ri";
import { HiMenuAlt2 } from "react-icons/hi";
import { Web3Button } from "@/components/wagmiComponents/Web3Button";
import jackpotImg from "../../../public/jackpot.png";

const Header = () => {
  return (
    <header className="flex flex-col items-center justify-between py-12 gap-4">
      <Image src={jackpotImg} alt="Jackpot logo" />
      <div className="pt-4">
        <Web3Button />
      </div>
    </header>
  );
};

export default Header;
