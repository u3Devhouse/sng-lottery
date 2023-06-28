import Link from "next/link";
import Image from "next/image";

const Footer = () => {
  return (
    <footer className="footer bg-dark flex justify-center flex-col flex-nowrap mt-12 items-center">
      <nav className="flex max-w-[1200px] flex-1 flex-row justify-between px-3 pt-4 pb-8 gap-x-72 self-center ">
        <div className="flex-col items-center gap-x-4 md:flex">
          <Link href="/">
            {/* <Image
                        src="/Logo_H.png"
                        alt="Logo"
                        width={602 / 3.2}
                        height={173 / 3.2}
                    /> */}
          </Link>
        </div>
        {/* <div className="hidden flex-col items-center gap-x-4 md:flex">
                <p className="text-white-900 text-lg my-1">Unicus Watch</p>
                <Link
                    href="/"
                    className="w-36 text-center text-lg font-light hover:underline "
                >
                    NFT Platform
                </Link>
                <Link
                    href=""
                    className="w-18 text-center text-lg font-light hover:underline lg:w-20"
                    target={"_blank"}
                >
                    Website
                </Link>


                {/* <Web3Button label="Connect" icon="hide" /> 
            </div>
            <div className="hidden flex-col items-center gap-x-4 md:flex">
                <p className="text-white-900 text-lg my-1">Information</p>
                <Link
                    href="/"
                    className="w-20 text-center text-lg font-light hover:underline"
                >
                    Privacy
                </Link>
                <Link
                    href=""
                    className="w-36 text-center text-lg font-light hover:underline lg:w-20"
                    target={"_blank"}
                >
                    Terms and Conditions
                </Link>


                {/* <Web3Button label="Connect" icon="hide" /> 
            </div> */}
      </nav>
      <div className="flex-col items-center gap-x-4 md:flex p-4 ">
        <p>2023 by Blaze Lottery. All rights Reserved.</p>
      </div>
    </footer>
  );
};

export default Footer;
