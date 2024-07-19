import { defaultWagmiConfig } from "@web3modal/wagmi/react/config";
import { bsc, bscTestnet } from "wagmi/chains";

import { cookieStorage, createStorage } from "wagmi";

// Your WalletConnect Cloud project ID
export const projectId = "9ba2cca8fb0951019c2b5136cad0fad6";

// Create a metadata object
const metadata = {
  name: "SNG Lottery",
  description: "Lottery game for SwapNGo",
  url: "https://jackpot.sngtoken.io", // origin must match your domain & subdomain
  icons: ["https://avatars.githubusercontent.com/u/37784886"],
};

// Create wagmiConfig
const chains = [bsc, bscTestnet] as const;
export const config = defaultWagmiConfig({
  chains,
  projectId,
  metadata,
  ssr: true,
  storage: createStorage({
    storage: cookieStorage,
  }),
});
