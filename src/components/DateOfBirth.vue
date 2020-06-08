<template>
    <v-container>
        <v-row justify="center">
            <v-date-picker
                    v-model="birthday"
                    locale="pt-BR"
                    :landscape="$vuetify.breakpoint.mdAndUp">
            </v-date-picker>
        </v-row>
    </v-container>
</template>

<script>
    import {mapState} from 'vuex'

    export default {
        name: 'DateOfBirth',
        computed: {
            ...mapState(['dob']),
            birthday: {
                set(dt) {
                    this.$store.commit('updateDob', dt + "T00:00:00+0000")
                },
                get() {
                    try {
                        return new Date(this.dob).toISOString().split('T')[0]
                    } catch {
                        return this.dob.split('T')[0]
                    }
                }
            }

        },
    }
</script>

<style scoped>
</style>
