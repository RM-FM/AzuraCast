<template>
    <tab
        :label="$gettext('Advanced')"
        :item-header-class="tabClass"
    >
        <div class="row g-3">
            <form-group-multi-check
                id="edit_form_backend_options"
                class="col-md-12"
                :field="v$.backend_options"
                :options="backendOptions"
                stacked
                :label="$gettext('Advanced Manual AutoDJ Scheduling Options')"
                :description="$gettext('Control how this playlist is handled by the AutoDJ software.')"
            />
        </div>
    </tab>
</template>

<script setup lang="ts">
import {useTranslate} from "~/vendor/gettext";
import FormGroupMultiCheck from "~/components/Form/FormGroupMultiCheck.vue";
import {useVuelidateOnFormTab} from "~/functions/useVuelidateOnFormTab";
import Tab from "~/components/Common/Tab.vue";
import {ApiGenericForm} from "~/entities/ApiInterfaces.ts";

const form = defineModel<ApiGenericForm>('form', {required: true});

const {v$, tabClass} = useVuelidateOnFormTab(
    form,
    {
        backend_options: {},
    },
    {
        backend_options: []
    }
);

const {$gettext} = useTranslate();

const backendOptions = [
    {
        value: 'interrupt',
        text: $gettext('Interrupt other songs to play at scheduled time.')
    },
    {
        value: 'single_track',
        text: $gettext('Only play one track at scheduled time.')
    },
    {
        value: 'merge',
        text: $gettext('Merge playlist to play as a single track.')
    },
    {
        value: 'prioritize',
        text: $gettext('Prioritize over listener requests.')
    }
];
</script>
