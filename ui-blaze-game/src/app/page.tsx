import CurrentCard from "@/components/lottery/CurrentCard";
import BuyTicketsModal from "@/components/lottery/BuyTicketsModal";
import PastRounds from "@/components/lottery/PastRounds";
import OwnerCard from "@/components/owner/OwnerCard";

const Page = () => {
  const isIframe = typeof window !== "undefined" && window !== window.top;
  return (
    <>
      {isIframe && (
        <section className="lg:hidden pb-12">
          <div className="flex flex-col items-center justify-center">
            <a
              className="link text-2xl"
              href="https://blaze-lottery.vercel.app/"
              target="_parent"
            >
              Mobile users use THIS site
            </a>
          </div>
        </section>
      )}
      <section className="w-full pb-4 flex flex-col items-center">
        <h2 className="italic font-outfit pb-4 text-2xl font-bold">
          Current Round
        </h2>
        <CurrentCard />
      </section>
      <section className="flex flex-col items-center py-12">
        <h2 className="italic font-outfit pb-4 text-2xl font-bold">
          Past Rounds
        </h2>
        <PastRounds />
      </section>
      <section className="flex flex-col items-center">
        <OwnerCard />
      </section>
      <BuyTicketsModal />
    </>
  );
};

export default Page;
