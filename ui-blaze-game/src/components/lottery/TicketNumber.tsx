import classNames from "classnames";

const TicketNumber = (props: { number: number; size?: "sm" | "normal" }) => {
  return (
    <div
      className={classNames(
        "rounded-full bg-slate-700 border-2 border-golden text-white flex-row flex items-center justify-center font-bold",
        props.size == "sm"
          ? "w-8 h-8 text-sm"
          : "w-8 h-8 md:w-12 md:h-12 md:text-lg text-base"
      )}
    >
      {props.number}
    </div>
  );
};

export default TicketNumber;
