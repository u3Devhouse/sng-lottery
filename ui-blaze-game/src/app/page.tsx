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

export function Page() {
  return (
    <>
      <h1>wagmi + Web3Modal + Next.js</h1>

      <Web3Button />

      <Connected>
        <hr />
        <h2>Network</h2>
        <NetworkSwitcher />
        <br />
        <hr />
        <h2>Account</h2>
        <Account />
        <br />
        <hr />
        <h2>Balance</h2>
        <Balance />
        <br />
        <hr />
        <h2>Block Number</h2>
        <BlockNumber />
        <br />
        <hr />
        <h2>Read Contract</h2>
        <ReadContract />
        <br />
        <hr />
        <h2>Read Contracts</h2>
        <ReadContracts />
        <br />
        <hr />
        <h2>Read Contracts Infinite</h2>
        <ReadContractsInfinite />
        <br />
        <hr />
        <h2>Send Transaction</h2>
        <SendTransaction />
        <br />
        <hr />
        <h2>Send Transaction (Prepared)</h2>
        <SendTransactionPrepared />
        <br />
        <hr />
        <h2>Sign Message</h2>
        <SignMessage />
        <br />
        <hr />
        <h2>Sign Typed Data</h2>
        <SignTypedData />
        <br />
        <hr />
        <h2>Token</h2>
        <Token />
        <br />
        <hr />
        <h2>Watch Contract Events</h2>
        <WatchContractEvents />
        <br />
        <hr />
        <h2>Watch Pending Transactions</h2>
        <WatchPendingTransactions />
        <br />
        <hr />
        <h2>Write Contract</h2>
        <WriteContract />
        <br />
        <hr />
        <h2>Write Contract (Prepared)</h2>
        <WriteContractPrepared />
      </Connected>
    </>
  );
}

export default Page;
