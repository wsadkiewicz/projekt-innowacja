import { LightningElement, wire } from 'lwc';
import getAnimals from '@salesforce/apex/AnimalFinderController.getAnimals';
import getShelters from '@salesforce/apex/AnimalFinderController.getShelters';
import getBreeds from '@salesforce/apex/AnimalFinderController.getBreeds';
import noImage from '@salesforce/resourceUrl/no_image';

export default class AnimalSearch extends LightningElement {
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
        const url = `/lightning/r/Animal__c/${animalId}/view`;
        window.open(url, '_blank');
    }

    handleFilterChange(event) {
        const fieldName = event.target.name;
        const value = event.target.value;

        this[fieldName] = value;
    }
}