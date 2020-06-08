import Vue from 'vue'
import App from './App.vue'
import store from './store'
import vuetify from './plugins/vuetify';

Vue.config.productionTip = false

export default new Vue({
    store,
    vuetify,
    render: h => h(App)
}).$mount('#app');

