"use client";

import { isIframeAtom } from "@/data/generalData";
import { Web3Button } from "@web3modal/react";
import classNames from "classnames";
import { useAtomValue } from "jotai";

export const IframeWeb3Button = () => {
  const isIframe = useAtomValue(isIframeAtom);

  return (
    <div className={classNames("pt-4", isIframe && "hidden md:block")}>
      <Web3Button />
    </div>
  );
};
