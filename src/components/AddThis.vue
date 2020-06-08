<template>
  <div class="social">
    <div class="fb-like"
         style="margin:0 auto;"
         data-href="https://www.facebook.com/meuastral/"
         data-layout="button_count"
         data-size="small"
         data-action="like">
    </div>
    &nbsp;
    <a href="https://twitter.com/MeuAstral_Com?ref_src=twsrc%5Etfw"
       class="twitter-follow-button"
       data-lang="pt"
       data-show-count="true">
      Seguir @MeuAstral_Com</a>
  </div>
</template>

<script>
    import {mapGetters} from "vuex"

    export default {
        name: "AddThis",
        created() {
            window.addthis_config = {
                data_track_clickback:true,
                data_ga_property:"UA-31528282-1",
                data_ga_social:true
            }
        },
        computed: {
            ...mapGetters(['localDob']),
            twText() {
                return `As pessoas nascidas em ${this.localDob} tem aproximadamente ${this.$parent.$parent.age_in_days()} dias de vida.`
            }
        }
    }
</script>

<style scoped>
.social {
  line-height: 12px;
}
</style>
