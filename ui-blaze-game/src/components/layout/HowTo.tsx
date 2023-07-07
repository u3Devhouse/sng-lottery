import Image from "next/image";

import howto1 from "@/../public/assets/Rectangle 6.png";
import howto2 from "@/../public/assets/Rectangle 7.png";
import howto3 from "@/../public/assets/Rectangle 9.png";
// pending assets for how to play icons

const HowTo = () => {
  return (
    <div className="flex justify-evenly flex-row flex-wrap mt-12 items-center px-2 font-outfit gap-4">
      <div className="flex flex-col items-center  max-w-xs bg-[#39253eb2] p-4 rounded-lg w-screen md:w-[320px]">
        <Image
          src={howto1}
          alt="How to icon 1"
          width={99 / 2}
          height={78 / 2}
        />
        <p className="text-white text-base text-center">
          Choose amount of tickets
        </p>
      </div>
      <div className="flex flex-col items-center  max-w-xs bg-[#39253eb2] p-4 rounded-lg w-screen md:w-[320px]">
        <Image
          src={howto2}
          alt="How to icon 2"
          width={75 / 2}
          height={80 / 2}
          // style={{ transform: "scaleX(-1)" }}
        />
        <p className="text-white text-base text-center">
          Choose your lucky number
        </p>
      </div>
      <div className="flex flex-col items-center  max-w-xs bg-[#39253eb2] p-4 rounded-lg w-screen md:w-[320px]">
        <Image
          src={howto3}
          alt="How to icon 3"
          width={69 / 2}
          height={68 / 2}
          // style={{ transform: "scaleX(1), scaleY(0.5)" }}
        />
        <p className="text-white text-base text-center">Claim any rewards</p>
      </div>
    </div>
  );
};

export default HowTo;
