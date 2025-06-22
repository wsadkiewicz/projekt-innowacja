import { LightningElement, wire } from 'lwc';
import getAnimals from '@salesforce/apex/AnimalFinderController.getAnimals';
import getShelters from '@salesforce/apex/AnimalFinderController.getShelters';
import getBreeds from '@salesforce/apex/AnimalFinderController.getBreeds';
import noImage from '@salesforce/resourceUrl/no_image';
import { NavigationMixin } from 'lightning/navigation';

const ICON_PATH = "M13.5 0C20.9558 0 27 6.04416 27 13.5C27 20.9558 20.9558 27 13.5 27C6.04416 27 0 20.9558 0 13.5C0 6.04416 6.04416 0 13.5 0ZM11.9199 6.26562C11.448 6.2101 10.9698 6.28836 10.54 6.49121C10.1665 6.65584 9.84802 6.92505 9.62305 7.26562C9.39807 7.60631 9.27526 8.00485 9.27051 8.41309V18.5869C9.27526 18.9952 9.39807 19.3937 9.62305 19.7344C9.84802 20.0749 10.1665 20.3442 10.54 20.5088C10.885 20.6668 11.2603 20.7489 11.6396 20.75C12.2114 20.7506 12.7659 20.5544 13.21 20.1943L19.3721 15.1074C19.6137 14.915 19.8092 14.6698 19.9434 14.3916C20.0774 14.1134 20.1475 13.8088 20.1475 13.5C20.1475 13.1912 20.0774 12.8866 19.9434 12.6084C19.8092 12.3302 19.6137 12.085 19.3721 11.8926L13.21 6.80566C12.839 6.50847 12.392 6.32117 11.9199 6.26562Z";

export default class AnimalSearch extends NavigationMixin(LightningElement) {
    selectedShelterId = '';
    selectedBreed = '';
    selectedAgeRange = '';
    selectedSex = '';

    animals = [];

    shelterOptions = [];
    breedOptions = [];
    ageRangeOptions = [
        { label: 'Any', value: '' },
        { label: '0-2 years', value: '0-2' },
        { label: '3-5 years', value: '3-5' },
        { label: '6-10 years', value: '6-10' },
        { label: '10+ years', value: '10+' }
    ];
    sexOptions = [
        { label: 'Any', value: '' },
        { label: 'Male', value: 'Male' },
        { label: 'Female', value: 'Female' }
    ];

    defaultImage = noImage;

    @wire(getShelters)
    wiredShelters({ error, data }) {
        if (data) {
            this.shelterOptions = [
                { label: 'Any', value: '' },
                ...data.map(shelter => ({
                    label: shelter.Name,
                    value: shelter.Id
                }))
            ];
        } else if (error) {
            this.shelterOptions = [];
        }
    }

    @wire(getBreeds)
    wiredBreeds({ error, data }) {
        if (data) {
            this.breedOptions = [
                { label: 'Any', value: '' },
                ...data.map(breed => ({
                    label: breed,
                    value: breed
                }))
            ];
        } else if (error) {
            this.breedOptions = [];
        }
    }

    @wire(getAnimals, { shelterId: '$selectedShelterId',
                        breed: '$selectedBreed', 
                        ageRange: '$selectedAgeRange', 
                        sex: '$selectedSex' })
    wiredAnimals({ error, data }) {
        if (data) {
            this.animals = data;
        } else if (error) {
            this.animals = [];
        }
    }

    handleAnimalClick(event) {
        const animalId = event.currentTarget.dataset.id;

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: animalId,
                objectApiName: 'Animal__c',
                actionName: 'view'
            }
        }).then((url) => {
            window.open(url, "_blank");
        });
    }

    handleFilterChange(event) {
        const fieldName = event.target.name;
        const value = event.target.value;

        this[fieldName] = value;
    }

    get iconPath() {
        return ICON_PATH;
    }
}