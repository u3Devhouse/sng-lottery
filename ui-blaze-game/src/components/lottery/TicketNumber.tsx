import classNames from "classnames";

const TicketNumber = (props: {
  number: number;
  size?: "sm" | "normal";
  variation?: "default" | "secondary" | "selected";
}) => {
  const variations = {
    default: "bg-number-bg border-secondary",
    secondary: "bg-number-bg-secondary border-secondary",
    selected: "border-primary bg-secondary-bg",
  };

  const variation = variations[props.variation || "default"];

  return (
    <div
      className={classNames(
        "rounded-full border-2 text-white flex-row flex items-center justify-center font-bold",
        variation,
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
