"use client";

import React, { ReactNode } from "react";
import { projectId } from "@/utils/web3/config";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

import { State, WagmiProvider, createConfig, http } from "wagmi";
import { bsc } from "viem/chains";
import { ConnectKitProvider, getDefaultConfig } from "connectkit";

const config = createConfig(
  getDefaultConfig({
    // Your dApps chains
    chains: [bsc],
    transports: {
      [bsc.id]: http(bsc.rpcUrls.default.http[0]),
    },
    // Required API Keys
    walletConnectProjectId: projectId,

    // Required App Info
    appName: "SNG Jackpot",

    // Optional App Info
    appDescription: "SNG Jackpot",
    appUrl: "https://jackpot.swapngo.io", // your app's url
    appIcon: "https://jackpot.swapngo.io/icon.png", // your app's icon, no bigger than 1024x1024px (max. 1MB)
  })
);

// Setup queryClient
const queryClient = new QueryClient();

if (!projectId) throw new Error("Project ID is not defined");

export default function Web3ModalProvider({
  children,
  initialState,
}: {
  children: ReactNode;
  initialState?: State;
}) {
  return (
    <WagmiProvider config={config} initialState={initialState}>
      <QueryClientProvider client={queryClient}>
        <ConnectKitProvider>{children}</ConnectKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}
