import { Account } from "@/components/wagmiComponents/Account";
import { Balance } from "@/components/wagmiComponents/Balance";
import { BlockNumber } from "@/components/wagmiComponents/BlockNumber";
import { Connected } from "@/components/wagmiComponents/Connected";
import { NetworkSwitcher } from "@/components/wagmiComponents/NetworkSwitcher";
import { ReadContract } from "@/components/wagmiComponents/ReadContract";
import { ReadContracts } from "@/components/wagmiComponents/ReadContracts";
import { ReadContractsInfinite } from "@/components/wagmiComponents/ReadContractsInfinite";
import { SendTransaction } from "@/components/wagmiComponents/SendTransaction";
import { SendTransactionPrepared } from "@/components/wagmiComponents/SendTransactionPrepared";
import { SignMessage } from "@/components/wagmiComponents/SignMessage";
import { SignTypedData } from "@/components/wagmiComponents/SignTypedData";
import { Token } from "@/components/wagmiComponents/Token";
import { WatchContractEvents } from "@/components/wagmiComponents/WatchContractEvents";
import { WatchPendingTransactions } from "@/components/wagmiComponents/WatchPendingTransactions";
import { Web3Button } from "@/components/wagmiComponents/Web3Button";
import { WriteContract } from "@/components/wagmiComponents/WriteContract";
import { WriteContractPrepared } from "@/components/wagmiComponents/WriteContractPrepared";

import CurrentCard from "@/components/lottery/CurrentCard";
import BuyTicketsModal from "@/components/lottery/BuyTicketsModal";
import PastRounds from "@/components/lottery/PastRounds";

export function Page() {
  return (
    <>
      <h1 className="text-4xl font-outfit font-bold drop-shadow-md text-center my-14">
        Get your tickets & Play!
      </h1>
      <section className="w-full py-4 px-4 flex flex-col items-center">
        <h2 className="underline font-outfit">Current Round</h2>
        <CurrentCard />
      </section>
      <section className="flex flex-col items-center">
        <h2 className="underline font-outfit">Past Rounds</h2>
        <PastRounds />
      </section>
      <BuyTicketsModal />
    </>
  );
}

export default Page;
