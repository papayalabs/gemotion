/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
    "./app/views/**/*.{erb,haml,html,slim}",
  ],
  theme: {
    extend: {
      keyframes: {
        'fade-in-up': {
          '0%': {
            opacity: '0',
            transform: 'translateY(10px)'
          },
          '100%': {
            opacity: '1',
            transform: 'translateY(0)'
          },
        }
      },
      animation :{
        'fade-in-up': 'fade-in-up 0.3s ease-in-out'
      },
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
        "custom-black": "#000",
        "custom-white": "#FFF",
        "custom-border": "#C9E1FF",
        "custom-blue": "#F2FCFF",
        "color-201F1F": "#201F1F",
        "color-C9E1FF": "#C9E1FF",
        "color-FFF": "#FFF",
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
        "677px": "677px",
        "99px": "99px",
        "15px": "15px",
        "27px": "27px",
      },
      borderRadius: {
        "20px": "20px",
        "10px": "10px",
      },
      boxShadow: {
        custom: "4px 4px 20px 5px rgba(13, 103, 131, 0.10)",
        "video-desc": "4px 4px 20px 5px rgba(13, 103, 131, 0.10)",
      },
      fontSize: {
        "18px": "18px",
        "20px": "20px",
        "32px": "32px", // Custom font size for text-4xl if needed
        "40px": "40px",
        "70px": "70px",
      },
      lineHeight: {
        "24px": "24px",
        "25px": "25px",
        "30px": "30px",
        "37px": "37px", // Custom line height for leading-[37px]        "56px": "56px",
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
