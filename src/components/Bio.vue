<template>
    <v-container>
        <v-row align="center" justify="center">
            <v-col cols="12" md="4">
                <BioCard activity="Físico" :cycle="23" color="blue" icon="mdi-arm-flex"/>
            </v-col>
            <v-col cols="12" md="4">
                <BioCard activity="Emocional" :cycle="28" color="red" icon="mdi-heart"/>
            </v-col>
            <v-col cols="12" md="4">
                <BioCard activity="Intelectual" :cycle="33" color="green" icon="mdi-brain"/>
            </v-col>
        </v-row>
    </v-container>
</template>

<script>
    import BioCard from "./BioCard"

    export default {
        name: "Bio",
        components: {
            BioCard,
        },
    }
</script>

<style scoped>
</style>
