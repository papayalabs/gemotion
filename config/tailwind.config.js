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
        "red-hat-display": [
          "'Red Hat Display'",
          ...defaultTheme.fontFamily.sans,
        ],
      },
      colors: {
        "shared-bg": "#201F1F",
      },
      spacing: {
        "14.43px": "14.43px",
        "16.78px": "16.78px",
        "28.32px": "28.32px",
      },
      lineHeight: {
        "25px": "25px",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
};
