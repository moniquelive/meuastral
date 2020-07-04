<template>
    <v-container>
        <v-expansion-panels
                focusable
                popout
                v-model.number="current"
                class="mb-6">
            <v-expansion-panel class="zodiac-sign-card" v-for="(h, i) in horoscope" :key="i">
                <v-expansion-panel-header disable-icon-rotate color="blue white--text">
                    <template v-slot:actions>
                        <v-icon color="orange lighten-3">mdi-zodiac-{{h.id}}</v-icon>
                    </template>
                    <v-row no-gutters>
                        <v-col cols="4">
                            <h2>{{h.name}}</h2>
                        </v-col>
                        <v-col cols="8">
                            <h3 class="font-italic">{{h.from}} a {{h.to}}</h3>
                        </v-col>
                    </v-row>
                </v-expansion-panel-header>
                <v-expansion-panel-content class="mt-6">
                    <p v-html="$options.filters.decode(h.resume)"></p>
                </v-expansion-panel-content>
            </v-expansion-panel>
        </v-expansion-panels>
    </v-container>
</template>

<script>
    import {mapState} from "vuex"

    const ranges = [
        [[new Date(1, 3, 21), new Date(1, 4, 20)]], // 21 de março a 20 de abril
        [[new Date(1, 4, 21), new Date(1, 5, 21)]], // 21 de abril a 21 de maio
        [[new Date(1, 5, 22), new Date(1, 6, 21)]], // 22 de maio a 21 de junho
        [[new Date(1, 6, 22), new Date(1, 7, 22)]], // 22 de junho a 22 de julho
        [[new Date(1, 7, 23), new Date(1, 8, 21)]], // 23 de julho a 21 de agosto
        [[new Date(1, 8, 22), new Date(1, 9, 23)]], // 22 de agosto a 23 de setembro
        [[new Date(1, 9, 24), new Date(1, 10, 23)]], // 24 de setembro a 23 de outubro
        [[new Date(1, 10, 24), new Date(1, 11, 22)]], // 24 de outubro a 22 de novembro
        [[new Date(1, 11, 23), new Date(1, 12, 22)]], // 23 de novembro a 22 de dezembro
        [[new Date(1, 12, 23), new Date(1, 12, 31)], [new Date(1, 1, 1), new Date(1, 1, 20)]], // 23 de dezembro a 20 de janeiro
        [[new Date(1, 1, 21), new Date(1, 2, 19)]], // 21 de janeiro a 19 de fevereiro
        [[new Date(1, 2, 20), new Date(1, 3, 20)]], // 20 de fevereiro a 20 de março
    ]

    export default {
        name: "Horoscope",
        data: () => ({
            current: 0,
        }),
        filters: {
            decode: (html) => {
                const txt = document.createElement("textarea")
                txt.innerHTML = html
                return txt.value
            },
        },
        computed: {
            ...mapState(['horoscope', 'dob']),
        },
        created() {
            this.$store.dispatch("fetchHoroscope") // refresh
        },
        methods: {
            inInterval(d, m, i) {
                const dt = new Date(1, m, d)
                return i.filter(x => (dt >= x[0]) && (dt <= x[1])).length > 0
            },
            horoscopeId() {
                const splitDate = this.dob.split('-'); // yyyy-mm-dd
                const day = parseInt(splitDate[2])
                const month = parseInt(splitDate[1])
                return ranges.map(r => this.inInterval(day, month, r)).indexOf(true)
            },
        },
        watch: {
            horoscope() {
                this.$nextTick(() => this.current = this.horoscopeId())
            },
            dob() {
                this.current = this.horoscopeId()
            },
        },
    }
</script>

<style scoped lang="scss">
</style>
