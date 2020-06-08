<template>
        <v-card
                shaped
                class="mx-auto"
                color="grey lighten-3"
                max-width="480">
            <v-card-text>
                <p class="subtitle-1 text-justify">As pessoas nascidas em <span class="font-weight-bold">{{ localDob }}</span>
                    possuem mais ou menos
                    <span class="font-weight-bold">{{ $root.$children[0].age_in_days() }}</span>
                    dias de vida.
                </p>
            </v-card-text>
            <v-card-actions class="px-4 pb-3">
                <AddThis/>
            </v-card-actions>
        </v-card>
</template>

<script>
    import {mapGetters} from "vuex"
    import AddThis from "./AddThis"

    export default {
        name: "UserInfo",
        components: {
            AddThis,
        },
        computed: {
            ...mapGetters(['localDob']),
        },
    }
</script>

<style scoped lang="scss">
</style>
