import { w3mConnectors, w3mProvider } from '@web3modal/ethereum'
import { configureChains, createConfig } from 'wagmi'
import { sepolia, mainnet } from 'wagmi/chains'

export const walletConnectProjectId = 'b7336212c4ce32d5f6f9cb00875897c7'

const { chains, publicClient, webSocketPublicClient } = configureChains(
  [mainnet, sepolia],
  [w3mProvider({ projectId: walletConnectProjectId })],
)

export const config = createConfig({
  autoConnect: true,
  connectors: w3mConnectors({
    chains,
    projectId: walletConnectProjectId,
    version: 2,
  }),
  publicClient,
  webSocketPublicClient,
})

export { chains }
