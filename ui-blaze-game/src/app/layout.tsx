import "../styles/globals.css";
import { Providers } from "./providers";
import Header from "@/components/layout/Header";
import Footer from "@/components/layout/Footer";
import { Roboto, Outfit } from "next/font/google";
import Image from "next/image";
import bgImage from "../../public/bg_flare.png";

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
  title: "Blaze Game",
  description: "Pick your numbers and win big!",
  image: "/blaze_logo.png",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${roboto.className} ${outfit.variable}`}>
      <body className="main-bg min-h-screen relative">
        <div className="-z-10 absolute top-0 left-0 max-h-[100%]">
          <Image
            src={bgImage}
            alt="background Flare"
            placeholder="blur"
            sizes="100vw"
            style={{ objectFit: "cover" }}
          />
          <Image
            src={bgImage}
            alt="background Flare"
            placeholder="blur"
            sizes="100vw"
            style={{ objectFit: "cover", transform: "scaleY(-1)" }}
          />
        </div>
        <Providers>
          <Header />
          {children}
          <Footer />
        </Providers>
      </body>
    </html>
  );
}
