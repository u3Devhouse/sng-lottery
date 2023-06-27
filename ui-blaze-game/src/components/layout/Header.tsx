import Link from "next/link";
import Image from "next/image";
import { TiSocialFacebook, TiSocialTwitter } from "react-icons/ti";
import { GrInstagram } from "react-icons/gr";
import { RiMessengerFill } from "react-icons/ri";
import { HiMenuAlt2 } from "react-icons/hi";

const Header = () => {
  return (
    <header className="flex w-full flex-row items-center justify-between px-8 pt-4 pb-8">
      <nav className="flex flex-grow flex-row items-center justify-between gap-x-4">
        <Link href="/">
          <Image src="/blaze_logo.png" alt="Logo" width={60} height={60} />
        </Link>
        <div className="hidden flex-row items-center gap-x-4 md:flex">
          <Link
            // href="https://blaze-lottery.com/"
            href="/"
            className="w-18 text-center text-lg font-light hover:underline lg:w-20"
            target={"_blank"}
          >
            Blaze Lottery
          </Link>

          {/* <Web3Button label="Connect" icon="hide" /> */}
        </div>
        <div className="md:hidden">
          <button>
            <HiMenuAlt2 className="text-4xl" />
          </button>
        </div>
      </nav>
    </header>
  );
};

export default Header;
