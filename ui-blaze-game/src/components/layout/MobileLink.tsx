"use client";

import { isIframeAtom } from "@/data/generalData";
import { useAtom } from "jotai";
import { useEffect, useState } from "react";

export const MobileLink = () => {
  const [isIframe, setIsIframe] = useAtom(isIframeAtom);

  useEffect(() => {
    if (!window) return;
    setIsIframe(window !== window.top);
  }, [setIsIframe]);
  return isIframe ? (
    <section className="lg:hidden pb-12">
      <div className="flex flex-col items-center justify-center">
        <a
          className="link text-2xl"
          href="https://blaze-lottery.vercel.app/"
          target="_parent"
        >
          Mobile users use THIS site
        </a>
      </div>
    </section>
  ) : null;
};
