/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.elm"],
  theme: {
    extend: {
      colors: {
        accent: "#F1C40F",
      },
      fontSize: {
        "2.5xl": "1.75rem",
      },
      dropShadow: {
        outline: "0 0 2px #334155"
      }
    },
  },
  plugins: [],
};
