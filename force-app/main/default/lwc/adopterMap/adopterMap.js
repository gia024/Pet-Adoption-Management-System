import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

const FIELDS = [
    'Adopter__c.Adopter_Location__Latitude__s',
    'Adopter__c.Adopter_Location__Longitude__s',
    'Adopter__c.Name'
];

export default class AdopterMap extends LightningElement {
    @api recordId;
    mapMarkers = [];
    error;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            const lat = data.fields.Adopter_Location__Latitude__s.value;
            const lon = data.fields.Adopter_Location__Longitude__s.value;
            const name = data.fields.Name.value;

            this.mapMarkers = [
                {
                    location: {
                        Latitude: lat,
                        Longitude: lon
                    },
                    title: name,
                    description: 'Adopter Location'
                }
            ];
            this.error = undefined;
        } else if (error) {
            this.error = 'Error loading map: ' + JSON.stringify(error);
            this.mapMarkers = [];
        }
    }
}