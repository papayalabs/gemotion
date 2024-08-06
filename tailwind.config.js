/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
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
        "title-color": "#0D6783",
        "custom-black": "var(--Black, #000)",
        "custom-white": "var(--White, #FFF)",
        "custom-border": "var(--linear-2-transparent-20, #C9E1FF)",
        "custom-blue": "#F2FCFF",
      },
      spacing: {
        "14.43px": "14.43px",
        "16.78px": "16.78px",
        "28.32px": "28.32px",
        "61px": "61px",
        "1062px": "1062px",
        "40px": "40px",
        "48px": "48px",
        "8px": "8px",
        "10px": "10px",
        "80px": "80px", // Add a custom spacing value of 80px,
        "405px": "405px", // Add a custom spacing value of 405px for width
      },
      borderRadius: {
        "20px": "20px",
        "10px": "10px",
      },
      boxShadow: {
        custom: "4px 4px 20px 5px rgba(13, 103, 131, 0.10)",
      },
      fontSize: {
        "18px": "18px",
        "20px": "20px",
        "40px": "40px",
        "70px": "70px",
      },
      lineHeight: {
        "24px": "24px",
        "25px": "25px",
        "30px": "30px",
        "56px": "56px",
        "81px": "81px",
      },
      letterSpacing: {
        "-1px": "-1px",
      },
      textColor: {
        transparent: "transparent",
      },
      backgroundImage: {
        "linear-dark-blue": "linear-gradient(248deg, #0D6783 0%, #163F50 100%)",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/container-queries"),
  ],
};
