import "../styles/globals.css";
import Web3Provider from "@/components/layout/Web3Provider";
import Header from "@/components/layout/Header";
import { Roboto, Outfit } from "next/font/google";

const roboto = Roboto({
  subsets: ["latin"],
  display: "swap",
  weight: ["400", "500", "700"],
});

const outfit = Outfit({
  subsets: ["latin"],
  variable: "--font-outfit",
});

export const metadata = {
  title: "Blaze Jackpot",
  description: "Pick your numbers and win big!",
  image: "/blaze_logo.png",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html
      lang="en"
      className={`${roboto.className} ${outfit.variable} main-bg`}
    >
      <body className="relative w-full min-h-screen">
        <div className="main-bg fixed top-0 w-screen h-screen -z-10" />
        <video
          autoPlay
          playsInline
          muted
          loop
          preload="auto"
          className="w-full fixed top-0 h-full object-cover -z-20 brightness-50"
        >
          <source src="/bg_stars.mp4" type="video/mp4" />
          Your browser does not support the video tag.
        </video>
        <Web3Provider>
          <Header />
          {children}
        </Web3Provider>
      </body>
    </html>
  );
}
