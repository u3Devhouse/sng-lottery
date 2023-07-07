import Link from "next/link";
import Image from "next/image";
import { TiSocialFacebook, TiSocialTwitter } from "react-icons/ti";
import { GrInstagram } from "react-icons/gr";
import { RiMessengerFill } from "react-icons/ri";
import { HiMenuAlt2 } from "react-icons/hi";
import { Web3Button } from "@/components/wagmiComponents/Web3Button";

const Header = () => {
  return (
    <header className="flex w-full flex-row items-center justify-between px-2 md:px-8 py-4 bg-secondary-bg header-shadow">
      <nav className="flex flex-grow flex-row items-center justify-between gap-x-4">
        <a
          href="https://blazetoken.io"
          rel="noopener noreferrer"
          className="flex flex-row items-center justify-center gap-x-4"
        >
          <Image src="/blaze_logo.png" alt="Logo" width={60} height={60} />
          <div className="text-lg italic font-bold text-primary-text uppercase whitespace-pre-wrap">
            Blaze{"\n"}Jackpot
          </div>
        </a>
        <div>
          <Web3Button />
        </div>
      </nav>
    </header>
  );
};

export default Header;
