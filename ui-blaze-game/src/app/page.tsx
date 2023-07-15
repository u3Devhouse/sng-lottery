import CurrentCard from "@/components/lottery/CurrentCard";
import BuyTicketsModal from "@/components/lottery/BuyTicketsModal";
import PastRounds from "@/components/lottery/PastRounds";
import OwnerCard from "@/components/owner/OwnerCard";

const Page = () => {
  return (
    <>
      <section className="w-full pb-4 flex flex-col items-center">
        <h2 className="italic font-outfit pb-4 text-2xl font-bold">
          Current Round
        </h2>
        <CurrentCard />
      </section>
      <section className="flex flex-col items-center pt-12">
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
