import { Gauge } from "@mui/x-charts/Gauge";

interface GaugeChartProps {
  value?: number;
  label?: string;
}

const AdminGaugeChart = ({
  value = 75,
  label = "Capacity",
}: GaugeChartProps) => {
  return (
    <div
      style={{
        width: 200,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        textAlign: "center",
      }}
    >
      <div style={{ width: 200, height: 200 }}>
        <Gauge
          value={value}
          startAngle={0}
          endAngle={360}
          innerRadius="80%"
          outerRadius="100%"
          text={({ value }) => `${value}%`}
        />
      </div>
      <div style={{ marginTop: 4, fontWeight: 600, fontSize: "0.875rem" }}>
        {label}
      </div>
    </div>
  );
};

export default AdminGaugeChart;
