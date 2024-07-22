"use client";

import { isIframeAtom } from "@/data/generalData";
import classNames from "classnames";
import { useAtomValue } from "jotai";
import { ConnectKitButton } from "connectkit";

export const IframeWeb3Button = () => {
  // const isIframe = useAtomValue(isIframeAtom);

  return (
    <div className={classNames("pt-4")}>
      <ConnectKitButton />
    </div>
  );
};
