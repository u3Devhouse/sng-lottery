"use client";
import { useState, useEffect } from "react";
import { WagmiConfig, mainnet, type Chain } from "wagmi";

import { createWeb3Modal, defaultWagmiConfig } from "@web3modal/wagmi/react";

const chains = [mainnet];
const projectId = "b7336212c4ce32d5f6f9cb00875897c7";
if (!projectId) throw new Error("NEXT_PUBLIC_PROJECT_ID is not set");

const metadata = {
  name: "Lynx Tech",
  description:
    "Lynx Tech is a Web3 project development company committed to enhancing everyones Web3 experience.",
  url: "https://lynxtech.io/",
  // icons: ['https://avatars.githubusercontent.com/u/37784886']
};

const wagmiConfig = defaultWagmiConfig({
  chains,
  projectId,
  metadata,
});

createWeb3Modal({
  wagmiConfig,
  projectId,
  chains,
  themeVariables: {
    "--w3m-accent": "#E0B654",
  },
});

export function Providers({ children }: { children: React.ReactNode }) {
  const [mounted, setMounted] = useState(false);
  useEffect(() => setMounted(true), []);
  return <WagmiConfig config={wagmiConfig}>{mounted && children}</WagmiConfig>;
}
