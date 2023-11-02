import { lotteryAbi, lotteryContract, uniswapPairAbi } from "@/data/contracts";
import { useEffect, useState } from "react";
import { zeroAddress } from "viem";
import { erc20ABI, readContracts, useAccount, useBalance, useContractReads } from "wagmi";

export const acceptedTokens = {
  'eth': {
    address: zeroAddress,
    ethPairAddress: zeroAddress
  },
  'blze' : {
    address: "0x1831186e1cBd4FA7F4F23D8453a68969067e34e1",
    ethPairAddress: "0x6BfCDA57Eff355A1BfFb76c584Fea20188B12166",
  },
  'shib':{
    address:"0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE",
    ethPairAddress: "0x811beEd0119b4AfCE20D2583EB608C6F7AF1954f"
  },
  'usdc':{
    address:"0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    ethPairAddress: zeroAddress
  },
  // 'usdt':{
  //   address:"0xdAC17F958D2ee523a2206206994597C13D831ec7",
  //   ethPairAddress: zeroAddress
  // },
  'preme':{
    address:"0x7d0C49057c09501595A8ce23b773BB36A40b521F",
    ethPairAddress: "0xE6b7e541e332346AB7a72059C6C09f12c6B0f3B5"
  },
  'bone':{
    address:"0x9813037ee2218799597d83D4a5B6F3b6778218d9",
    ethPairAddress: "0xf7d31825946e7fd99ef07212d34b9dad84c396b7"
  },
  'leash':{
    address:"0x27C70Cd1946795B66be9d954418546998b546634",
    ethPairAddress: "0x874376be8231dad99aabf9ef0767b3cc054c60ee"
  },
  // 'etherax':{
  //   address:"0x3b11f0B0A99B5B83110Fae19953e0B549CDCcCa9",
  //   ethPairAddress: "0xc45e05aca37a11a7b6fcdc20124646de362342d4"
  // },
  'volt':{
    address:"0x7f792db54B0e580Cdc755178443f0430Cf799aCa",
    ethPairAddress: "0x96aa22baedc5a605357e0b9ae20ab6b10a472e03"
  },
  // 'doge':{
  //   address:"0x4206931337dc273a630d328da6441786bfad668f",
  //   ethPairAddress: "0xfcd13ea0b906f2f87229650b8d93a51b2e839ebd"
  // },
  // 'mswap':{
  //   address:"0x4be2b2c45b432ba362f198c08094017b61e3bdc6",
  //   ethPairAddress: "0x929c4f3f7528f64d1ab93554e2497503f233e2d8"
  // },
  // 'wlunc':{
  //   address:"0xd2877702675e6ceb975b4a1dff9fb7baf4c91ea9",
  //   ethPairAddress: "0x60a39010e4892b862d1bb6bdde908215ac5af6f3"
  // },
  'bad':{
    address:"0x32b86b99441480a7E5BD3A26c124ec2373e3F015",
    ethPairAddress: "0x29c830864930c897efa2b9e9851342187b82010e"
  },
  // 'wsm':{
  //   address:"0xB62E45c3Df611dcE236A6Ddc7A493d79F9DFadEf",
  //   ethPairAddress: "0xacfc50ec5fe0fd039e83380b8ab343b77a49704f"
  // },
  // 'wbtc':{
  //   address:"0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599",
  //   ethPairAddress: "0xbb2b8038a1640196fbe3e38816f3e67cba72d940"
  // },
  // 'inedible':{
  //   address:"0x3486b751a36F731A1bEbFf779374baD635864919",
  //   ethPairAddress: "0xBDAC5B5AA51B99C6C11ce05df4A1C78CECc2375B"
  // },
  'dai':{
    address:"0x6B175474E89094C44Da98b954EedeAC495271d0F",
    ethPairAddress: zeroAddress
  },
  // 'xfund':{
  //   address:"0x892A6f9dF0147e5f079b0993F486F9acA3c87881",
  //   ethPairAddress: "0xab2D2F5bc36620A57Ec4bB60D6A7Df2a847dEab5"
  // },
  'shib2':{
    address:"0x2dE7B02Ae3b1f11d51Ca7b2495e9094874A064c0",
    ethPairAddress: "0x22479662Bd1561b45da6F27331d9b154eF7D15B5"
  },
  // 'tyrion':{
  //   address:"0x5e27e384aCBBa20982f991893B9970AaF3f43181",
  //   ethPairAddress: "0x5fe638845642444A9090AbFDe0DC3c602945a348"
  // },
  // 'bwsm':{
  //   address:"0xc3c7b03335eb950a2a9207ac5cac0571de34d844",
  //   ethPairAddress: "0xAeFF675a65EebFB3fBCA70942f199b1eF852ce06"
  // },
  // 'apx':{
  //   address:"0xed4e879087ebd0e8a77d66870012b5e0dffd0fa4",
  //   ethPairAddress: "0x2dC9050D9873F50526E467e983D435E6D8d9Afb0"
  // },
  'jesus':{
    address:"0xba386A4Ca26B85FD057ab1Ef86e3DC7BdeB5ce70",
    ethPairAddress: "0x8f1B19622a888c53C8eE4F7D7B4Dc8F574ff9068"
  },
  // 'shezmu':{
  //   address:"0x5fe72ed557d8a02fff49b3b826792c765d5ce162",
  //   ethPairAddress: "0x74E6cAc32234133Fe06bD0f4D8237dEe1dedE057"
  // },
  // 'shiba':{
  //   address:"0xfd1450a131599ff34f3be1775d8c8bf79e353d8c",
  //   ethPairAddress: "0xbEF860db27Fc2f9668d13D624563d859C65a2B25"
  // },
  // 'bones':{
  //   address:"0xe7c8537F92b4fEEFdc19bd6b4023dFe79400cb30",
  //   ethPairAddress: "0x5208890448B4FAc76378367Fb6087bCA8a8e8640"
  // },
}
export type AcceptedTokens = keyof typeof acceptedTokens;
export const tokenList = Object.keys(acceptedTokens) as Array<AcceptedTokens>;

type ContractCall = {
  address: string,
  abi: any,
  functionName: string,
  args?: Array<any>,
}

const tokenListContracts = tokenList.reduce( (info, token, index) => {
  info.tokens[token] = {
    startIndex: info.tokens[token]?.startIndex ?? info.calls.length,
    totalCalls: 0
  }
  if(token === 'eth'){
    info.calls.push({
      address: lotteryContract,
      abi: lotteryAbi,
      functionName: "acceptedTokens",
      args: [acceptedTokens[token].address]
    })
    info.tokens[token].totalCalls = 1;
    return info
  }

  info.calls.push({
    address: acceptedTokens[token].address,
    abi: erc20ABI,
    functionName: "balanceOf",
  } as const)
  info.calls.push({
    address: acceptedTokens[token].address,
    abi: erc20ABI,
    functionName: "allowance",
  } as const)
  info.calls.push({
    address: acceptedTokens[token].address,
    abi: erc20ABI,
    functionName: "decimals",
  } as const)
  info.calls.push({
    address: lotteryContract,
    abi: lotteryAbi,
    functionName: "acceptedTokens",
    args: [acceptedTokens[token].address]
  })
  if(acceptedTokens[token].ethPairAddress !== zeroAddress){
    info.calls.push({
      address: acceptedTokens[token].ethPairAddress,
      abi: uniswapPairAbi,
      functionName:"getReserves"
    })
    info.tokens[token].totalCalls = 5;
  }
  else
    info.tokens[token].totalCalls = 5;

  return info
}, { calls: [], tokens: {}} as { calls: Array<ContractCall>, tokens: Record<string, { startIndex: number, totalCalls: number }>})

export default function useAcceptedTokens(){

    const { address } = useAccount();
    const { data: ethBalance } = useBalance({ address })

    const fullList = tokenListContracts.calls.map(call => {
      if(call.functionName == "allowance")
        return { ...call, args: [address, lotteryContract], address: call.address as `0x${string}` }
      if(call.functionName == "balanceOf")
        return { ...call, args: [address], address: call.address as `0x${string}` }
      else
        return {...call, address: call.address as `0x${string}`}
    })

    const [allTokenData, setAllTokenData] = useState<any | undefined>(undefined)

    useEffect(() => {

      const readData = async () => {
        const data = await readContracts({ contracts: fullList})
        setAllTokenData(data)
      }
      if(!address)
        return;
      const interval = setInterval(readData, 3000)
      return () => clearInterval(interval)
    },[address, setAllTokenData, fullList])

    return { contractData: allTokenData, ethBalance, tokenListContracts, tokenList}
}