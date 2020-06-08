import Vue from 'vue'
import Vuex from 'vuex'
import VuexPersist from 'vuex-persist'

Vue.use(Vuex)

const vuexPersist = new VuexPersist({
  key: 'meuastral',
  storage: window.localStorage
})

const dateRange = {
  aquarius: {from: "21 de Janeiro", to: "19 de Fevereiro"},
  pisces: {from: "20 de Fevereiro", to: "20 de Março"},
  aries: {from: "21 de Março", to: "20 de Abril"},
  taurus: {from: "21 de Abril", to: "21 de Maio"},
  gemini: {from: "22 de Maio", to: "21 de Junho"},
  cancer: {from: "22 de Junho", to: "22 de Julho"},
  leo: {from: "23 de Julho", to: "21 de Agosto"},
  virgo: {from: "22 de Agosto", to: "23 de Setembro"},
  libra: {from: "24 de Setembro", to: "23 de Outubro"},
  scorpio: {from: "24 de Outubro", to: "22 de Novembro"},
  sagittarius: {from: "23 de Novembro", to: "22 de Dezembro"},
  capricorn: {from: "23 de Dezembro", to: "20 de Janeiro"},
}

export default new Vuex.Store({
  plugins: [vuexPersist.plugin],
  state: {
    dob: new Date().toISOString().split('T')[0],
    horoscope: [],
  },
  mutations: {
    updateDob(state, dt) {
      state.dob = dt
    },
    updateHoroscope(state, h) {
      state.horoscope = h
    },
  },
  actions: {
    fetchHoroscope({commit}) {
      fetch("http://p1.trrsf.com/cengine/horoscopo/card-sign?country=br&language=pt")
        .then(response => response.json())
        .then(json => json['signs_list'])
        .then(signs => signs.map(z => ({
          ...z,
          from: dateRange[z.id].from,
          to: dateRange[z.id].to,
        })))
        .then(horoscope => commit("updateHoroscope", horoscope))
        .catch(error => console.error(error))
    }
  },
  getters: {
    localDob(state) {
      const date = new Date(state.dob.split('T')[0])
      const timeDiff = date.getTimezoneOffset() * 60000;
      const adjustedDate = new Date(date.valueOf() + timeDiff);
      return adjustedDate.toLocaleDateString('pt-BR');
    },
  },
})
