<template>
  <v-app>
    <v-app-bar app
               :height="150+25"
               src="./assets/meuastral-marca.png"
               elevate-on-scroll
               color="light-blue darken-2">
      <template #img="{ props }">
        <v-img v-bind="props"
               width="300px"
               contain
               class="mx-auto"
               :height="150+25"
        ></v-img>
      </template>
    </v-app-bar>
    <v-content>
      <v-container>
        <h2 class="display-1 secondary--text">Data de Nascimento</h2>
        <v-divider></v-divider>
        <DateOfBirth/>
        <br>
        <UserInfo/>
        <br>

        <h2 class="display-1 secondary--text">Horóscopo</h2>
        <v-divider></v-divider>
        <Horoscope/>
        <br>

        <h2 class="display-1 secondary--text">Biorritmo</h2>
        <v-divider></v-divider>
        <Bio/>
        <br>

        <h3 class="mb-12 text-center display-2">Curtiu o MeuAstral.com? Deixe
          um recado, dúvida ou
          sugestão!</h3>
        <div class="text-center">
          <div class="fb-comments"
               data-href="meuastral.com"
               data-numposts="2"
               data-width=""></div>
        </div>
      </v-container>
    </v-content>
    <v-footer app>
      <v-row justify="space-between">
        <v-col md="4">
          <v-btn class="mx-2" fab dark small
                 color="primary"
                 target="_blank"
                 href="https://www.facebook.com/meuastral/">
            <v-icon dark>mdi-facebook</v-icon>
          </v-btn>
          <v-btn class="mx-2" fab dark small
                 color="primary"
                 target="_blank"
                 href="https://twitter.com/MeuAstral_Com">
            <v-icon dark>mdi-twitter</v-icon>
          </v-btn>
        </v-col>
        <v-col md="4" class="text-right">
          <span>{{ new Date().getFullYear() }} — <strong>MeuAstral</strong></span>
        </v-col>
      </v-row>
    </v-footer>
  </v-app>
</template>

<script>
  import DateOfBirth from './components/DateOfBirth'
  import UserInfo from './components/UserInfo'
  import Horoscope from "./components/Horoscope"
  import Bio from "./components/Bio"
  import {mapState} from "vuex"

  export default {
    name: 'App',
    components: {
      DateOfBirth,
      UserInfo,
      Horoscope,
      Bio,
    },
    computed: {
      ...mapState(['dob']),
    },
    methods: {
      age_in_days(from = new Date()) {
        return Math.trunc((from.getTime() - new Date(this.dob.split('T')[0]).getTime()) / (1000 * 3600 * 24))
      }
    },
  }

</script>

<style lang="scss">
  @import "./assets/roboto.css";

  $mdi-font-path: "~@mdi/font/fonts";
  @import "~@mdi/font/scss/materialdesignicons.scss";

  body {
    padding-bottom: 20px;
  }
</style>
