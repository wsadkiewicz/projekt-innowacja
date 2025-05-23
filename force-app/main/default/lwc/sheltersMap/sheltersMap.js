import { LightningElement, wire, api } from 'lwc';
import getSheltersByCity from '@salesforce/apex/ShelterController.getSheltersByCity';

const ZOOM_LEVEL_VALUE = 10;
const LIST_VIEW_TYPE = "hidden";

const CURRENT_SHELTER_MARKER_ICON = {
    path: 'M400 0C558.22 0 686.956 128.728 686.956 286.958C686.956 395.561 658.019 434.947 421.689 788.409C416.847 795.651 408.713 800 400 800C391.288 800 383.152 795.652 378.312 788.408C141.972 434.824 113.044 396.708 113.044 286.956C113.044 128.728 241.78 0.000115873 400 0ZM399.71 113C395.784 113 391.296 113.56 387.37 117.483L243.609 242.686C239.683 246.609 238 251.092 238 256.136C238 266.28 245.853 274.126 255.949 274.126H273.898V313.188C273.842 313.693 273.842 314.253 273.842 314.758V377.526C273.842 389.912 283.882 399.944 296.278 399.944H305.253C305.926 399.944 306.599 399.888 307.272 399.832C308.114 399.888 308.955 399.944 309.796 399.944H341.151C353.547 399.944 363.588 389.912 363.588 377.526V328.208C363.588 318.288 371.608 310.275 381.536 310.274H417.435C427.363 310.274 435.384 318.288 435.384 328.208V377.526C435.384 389.912 445.424 399.944 457.82 399.944H471.282L489.512 400C490.297 400 491.082 400 491.867 399.944C492.484 400 493.102 400 493.719 400H502.693C515.089 400 525.129 389.968 525.129 377.582V368.504C525.297 366.991 525.41 365.477 525.41 363.964L525.018 274.182H542.966C552.501 274.182 560.915 266.279 560.915 256.191C561.476 251.148 559.232 246.664 554.745 242.741L411.489 116.923C408.124 114.121 403.636 113 399.71 113Z',
    fillColor: '#e94234',
    fillOpacity: 1,
    strokeWeight: 2,
    strokeColor: '#AF3228',
    scale: 0.06,
    anchor: { x: 400, y: 800 }
};

const OTHER_SHELTER_MARKER_ICON = {
    path: 'M256,0C154.739,0,72.348,82.386,72.348,183.652c0,70.241,18.514,94.635,169.771,320.929 C245.217,509.217,250.424,512,256,512s10.782-2.783,13.881-7.418c151.251-226.216,169.771-251.423,169.771-320.929 C439.652,82.386,357.261,0,256,0z M256,267.13c-46.032,0-83.478-37.446-83.478-83.478c0-46.032,37.446-83.478,83.478-83.478 s83.478,37.446,83.478,83.478C339.478,229.684,302.032,267.13,256,267.13z',
    fillColor: '#55babf',
    fillOpacity: 1,
    strokeWeight: 2,
    strokeColor: '#458083',
    scale: 0.08,
    anchor: { x: 256, y: 512 }
};

export default class Map extends LightningElement {
    @api recordId;
    mapMarkers;
    zoomLevel = ZOOM_LEVEL_VALUE;
    listView = LIST_VIEW_TYPE;
    error;

    @wire(getSheltersByCity, { currentShelterId: '$recordId' })
    wiredShelters({ error, data }) {
        if (data) {
            this.mapMarkers = data.map(shelter => ({
                location: {
                    Street: shelter.Address__Street__s,
                    City: shelter.Address__City__s,
                    PostalCode: shelter.Address__PostalCode__s,
                    State: shelter.Address__StateCode__s,
                    Country: shelter.Address__CountryCode__s
                },
                title: shelter.Name,
                description: 
                    (shelter.Address__Street__s || '') + '<br>' +
                    (shelter.Address__PostalCode__s || '') + ' ' +
                    (shelter.Address__City__s || ''),
                mapIcon :
                shelter.Id === this.recordId ? CURRENT_SHELTER_MARKER_ICON : OTHER_SHELTER_MARKER_ICON
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.mapMarkers = [];
        }
    }
}