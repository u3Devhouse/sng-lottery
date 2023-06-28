/** @type {import('tailwindcss').Config} */
module.exports = {
  daisyui:{
    base: false,
    themes:[
      {
        'mytheme':{
          'accent': "#F94F59"
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
        'secondary-bg' : "#1D152B",
        'primary-text': "#D6B159",
        'golden': "#E0B654"
      },
      fontFamily:{
        'outfit': ['var(--font-outfit)'],
      }
    },
  },
  plugins: [require("daisyui")],
}

