import Image from "next/image";

import tinyflame from "@/../public/assets/tiny_flame.png";
// pending assets for how to play icons

const stepContainer = 'flex-col flex-1 items-center gap-x-4 md:flex p-4 shadow-md rounded-lg border-0 bg-gray-800 opacity-90 min-w-max max-w-xs'

const HowTo = () => {
    return (
        <div className="footer bg-dark flex justify-evenly flex-row flex-nowrap mt-12 items-center">
            <div className={stepContainer}>
                <Image
                    src={tinyflame}
                    alt="tiny_flame.png"
                    width={50}
                    height={50}
                // style={{ transform: "scaleX(-1)" }}
                />
                <p>Choose amount of tickets</p>
            </div>
            <div className={stepContainer}>
                <Image
                    src={tinyflame}
                    alt="tiny_flame.png"
                    width={50}
                    height={50}
                // style={{ transform: "scaleX(-1)" }}
                />
                <p>Choose your lucky number</p>

            </div>
            <div className={stepContainer}>
                <Image
                    src={tinyflame}
                    alt="tiny_flame.png"
                    width={50}
                    height={50}
                // style={{ transform: "scaleX(1), scaleY(0.5)" }}
                />
                <p>Claim any rewards</p>

            </div>

        </div>
    );
};

export default HowTo;
