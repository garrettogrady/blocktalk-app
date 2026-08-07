import { TrendingUp, TrendingDown, Minus } from "lucide-react";

interface TrendCardProps {
  label: string;
  value: number | string;
  previousValue?: number;
  currentValue?: number;
  suffix?: string;
}

export default function TrendCard({
  label,
  value,
  previousValue,
  currentValue,
  suffix,
}: TrendCardProps) {
  let trendPercent: number | null = null;
  let direction: "up" | "down" | "flat" = "flat";

  if (previousValue != null && currentValue != null && previousValue > 0) {
    trendPercent = Math.round(
      ((currentValue - previousValue) / previousValue) * 100
    );
    if (trendPercent > 0) direction = "up";
    else if (trendPercent < 0) direction = "down";
  }

  const trendColors = {
    up: "text-green-600",
    down: "text-red-600",
    flat: "text-gray-400",
  };

  return (
    <div className="bg-white rounded-lg border border-gray-200 p-5">
      <p className="text-sm text-gray-500 font-medium">{label}</p>
      <div className="flex items-end gap-2 mt-1">
        <p className="text-2xl font-bold">
          {value}
          {suffix && (
            <span className="text-sm font-normal text-gray-400 ml-1">
              {suffix}
            </span>
          )}
        </p>
        {trendPercent != null && (
          <span
            className={`flex items-center gap-0.5 text-xs font-medium mb-1 ${trendColors[direction]}`}
          >
            {direction === "up" && <TrendingUp size={14} />}
            {direction === "down" && <TrendingDown size={14} />}
            {direction === "flat" && <Minus size={14} />}
            {Math.abs(trendPercent)}%
          </span>
        )}
      </div>
    </div>
  );
}
