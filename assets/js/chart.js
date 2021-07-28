import _css from "uplot/dist/uPlot.min.css";
import uPlot from "uplot";

export const ChartHook = {
  mounted() {
    this.trades = [];
    this.plot = new uPlot(plotOptions(), [[], []], this.el);
  },
  updated() {
    const price = this.el.dataset.price;
    const timestamp = parseInt(this.el.dataset.tradedAt);
    const tradedAt = new Date(timestamp);

    this.trades.push({
      timestamp,
      price,
    });

    if (this.trades.length > 20) {
      this.trades.splice(0, 1);
    }

    this.updateChart();
  },
  updateChart() {
    const x = this.trades.map((t) => t.timestamp);
    const y = this.trades.map((t) => t.price);
    this.plot.setData([x, y]);
  },
};

const plotOptions = () => ({
  width: 230,
  height: 35,
  class: "chart-container",
  cursor: { show: false },
  select: { show: false },
  legend: { show: false },
  scales: {},
  axes: [{ show: false }, { show: false }],
  series: [
    {},
    {
      size: 0,
      width: 1,
      stroke: "rgb(99, 102, 241)",
      fill: "rgb(243, 244, 246)",
    },
  ],
});
