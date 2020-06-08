<template>
    <v-lazy>
        <v-card class="mt-4 mx-auto">
            <v-sheet
                    class="v-sheet--offset mx-auto"
                    :color="color"
                    elevation="12"
                    max-width="calc(100% - 32px)">
                <v-sparkline
                        :value="value"
                        color="white"
                        auto-line-width
                        padding="16"
                        auto-draw
                ></v-sparkline>
            </v-sheet>

            <v-card-text class="d-flex justify-center align-center">
                <v-chip class="ma-2">
                    <v-avatar left>
                        <v-icon :color="color">{{icon}}</v-icon>
                    </v-avatar>
                    <span class="title font-weight-light">{{activity}}</span>
                </v-chip>
                <v-chip class="ma-2 white--text" :color="color">
                    {{bio(cycle) | scale | toFixed(2)}}%
                </v-chip>
            </v-card-text>
        </v-card>
    </v-lazy>
</template>

<script>
    export default {
        name: "BioCard",
        props: {
            activity: String,
            cycle: Number,
            color: String,
            icon: String,
        },
        filters: {
            scale: (r) => (((r + 1) / 2.0) * 100.0),
            toFixed: (x, n) => x.toFixed(n),
        },
        computed: {
            value() {
                const days = 60
                return Array.from(Array(days).keys()).reverse().map((d) => {
                    const dt = new Date()
                    dt.setDate(dt.getDate() - d)

                    const bio = this.bio(this.cycle, dt)
                    return this.$options.filters.scale(bio)
                })
            }
        },
        methods: {
            bio(n, date = new Date()) {
                const ageInDays = this.$root.$children[0].age_in_days(date)
                return Math.sin(2 * Math.PI * ageInDays / n)
            }
        }
    }
</script>

<style scoped lang="scss">
</style>
