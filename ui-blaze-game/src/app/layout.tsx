import "../styles/globals.css";
import { Providers } from "./providers";
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
      <body className="main-bg relative w-[100vw]">
        <video
          autoPlay
          playsInline
          muted
          loop
          preload="auto"
          className="w-full fixed top-0 h-full object-cover -z-10 brightness-50"
        >
          <source src="/bg_vid.mp4" type="video/mp4" />
          Your browser does not support the video tag.
        </video>
        <Providers>
          <Header />
          {children}
        </Providers>
      </body>
    </html>
  );
}
