import Link from "next/link";
import Image from "next/image";
import { TiSocialFacebook, TiSocialTwitter } from "react-icons/ti";
import { GrInstagram } from "react-icons/gr";
import { RiMessengerFill } from "react-icons/ri";
import { HiMenuAlt2 } from "react-icons/hi";
import { Web3Button } from "@/components/wagmiComponents/Web3Button";

const Header = () => {
  return (
    <header className="flex w-full flex-row items-center justify-between px-8 py-4 bg-secondary-bg header-shadow">
      <nav className="flex flex-grow flex-row items-center justify-between gap-x-4">
        <Link
          href="/"
          className="flex flex-row items-center justify-center gap-x-4"
        >
          <Image src="/blaze_logo.png" alt="Logo" width={60} height={60} />
          <div className="text-2xl italic font-bold text-primary-text uppercase">
            Blaze Lottery
          </div>
        </Link>
        <div>
          <Web3Button />
        </div>
      </nav>
    </header>
  );
};

export default Header;
