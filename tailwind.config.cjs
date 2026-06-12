const typography = require('@tailwindcss/typography');
const daisyui = require('daisyui');

module.exports = {
  content: [
    './config/**/*.toml',
    './content/**/*.{html,md}',
    './src/**/*.{elm,js}',
    './themes/meuastral/layouts/**/*.html',
    './themes/meuastral/static/**/*.css'
  ],
  safelist: [
    'badge',
    'badge-lg',
    'btn',
    'btn-circle',
    'card',
    'card-body',
    'card-compact',
    'card-title',
    'indicator',
    'indicator-item',
    'indicator-start',
    'prose',
    'shadow-xl',
    'tooltip',
    'tooltip-bottom'
  ],
  theme: {
    extend: {}
  },
  plugins: [
    typography,
    daisyui
  ],
  daisyui: {
    logs: false,
    themes: ['light', 'aqua']
  }
};
