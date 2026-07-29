interface StatCardProps {
  label: string;
  value: number | string;
  accent?: "default" | "yellow" | "red" | "green";
}

const accentColors = {
  default: "border-l-blue-500",
  yellow: "border-l-yellow-500",
  red: "border-l-red-500",
  green: "border-l-green-500",
};

export default function StatCard({
  label,
  value,
  accent = "default",
}: StatCardProps) {
  return (
    <div
      className={`bg-white rounded-lg border border-gray-200 border-l-4 ${accentColors[accent]} p-5`}
    >
      <p className="text-sm text-gray-500 font-medium">{label}</p>
      <p className="text-2xl font-bold mt-1">{value}</p>
    </div>
  );
}
