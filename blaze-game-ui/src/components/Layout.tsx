import type { ReactNode } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";




const Layout = (props: { children: ReactNode }) => {
    const { children } = props;
    return (
        <div className="flex min-h-screen flex-col bg-[url('/assets/std_bg.png')] bg-cover bg-no-repeat">
            <Header />
            <main className="flex-grow">{children}

            </main>
            <Footer />
        </div>
    );
};

export default Layout;
