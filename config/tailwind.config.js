const defaultTheme = require("tailwindcss/defaultTheme");

module.exports = {
  content: [
    "./public/*.html",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Montserrat", "Inter var", ...defaultTheme.fontFamily.sans],
      },
      colors: {
        "header-bg": "#201F1F",
      },
      spacing: {
        "14.43px": "14.43px",
        "16.78px": "16.78px",
        "28.32px": "28.32px",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
};
