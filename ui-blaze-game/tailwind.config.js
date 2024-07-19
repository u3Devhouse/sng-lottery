/** @type {import('tailwindcss').Config} */
module.exports = {
  daisyui:{
    base: false,
    themes:[
      {
        'mytheme':{
          'primary': "#E30613",
          'accent': "#F94F59",
          'secondary': "#FFE5B6" 
        }
      }
    ]
  },
  content: [
    "./src/**/*.{js,ts,jsx,tsx,mdx}"
  ],
  theme: {
    extend: {
      colors:{
        'primary-bg': "#27072A",
        'secondary-bg' : "#06101D",
        'primary-text': "#D6B159",
        'secondary-light-bg': "#FFE5B6",
        'golden': "#E0B654",
        'golden-dark': "#D2A64C",
        'sng-red': "#E30613",
        'number-bg' : "#2A467E",
        'number-bg-secondary': "#C30712",
        'dark-red': "#5B050A"
      },
      fontFamily:{
        'outfit': ['var(--font-outfit)'],
      }
    },
  },
  plugins: [require("daisyui")],
}

