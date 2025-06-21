import { LightningElement, track } from 'lwc';
import getMissingAnimals from '@salesforce/apex/MissingAnimalsService.getMissingAnimals';
import updateAnimalFoundStatus from '@salesforce/apex/MissingAnimalsService.updateAnimalFoundStatus';
import createMissingAnimalReport from '@salesforce/apex/MissingAnimalsService.createMissingAnimalReport';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import noImage from '@salesforce/resourceUrl/no_image';

export default class MissingAnimals extends LightningElement {
    animals = [];
    isLoading = false;
    error;
    dayDelta = 7;
    
    showForm = false;
    formData = {};
    
    defaultImage = noImage;

    connectedCallback() {
        this.loadAnimals();
    }

    loadAnimals() {
        this.isLoading = true;
        
        getMissingAnimals({ dayDelta: this.dayDelta })
            .then(result => {
                console.log('Raw data from server:', result);
                this.animals = result;
            })
            .catch(error => {
                this.animals = [];
            })
            .finally(() => {
            this.isLoading = false;
            });
    }

    get hasAnimals() {
        return this.animals?.length > 0;
    }

    handleDayDeltaChange(event) {
        if (event.target.value != '') {
            this.dayDelta = parseInt(event.target.value);
            this.loadAnimals();
        }
    }

    get formattedAnimals() {
        return this.animals.map(animal => ({
            ...animal,
            formattedDate: animal.missingDate.split('T')[0]
        }));
    }

    handleCreateNew() {
        this.showForm = true;
        this.formData = {
            name: '',
            imageUrl: '',
            breed: '',
            age: '',
            uniqueFeatures: '',
            size: '',
            
            address: '',
            disappearancePlaceLongitude: '',
            disappearancePlaceLatitude: '',
            disappearanceDate: '',
            description: ''
        };
    }

    handleFormCancel() {
        this.showForm = false;
        this.formData = {};
    }

    handleFormFieldChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        
        this.formData = {
            ...this.formData,
            [field]: value
        };
    }

    handleFormSubmit() {
        if (!this.validateFormName()) {
            return;
        }

        const missingAnimalWrapper = {
            animal: {
                name: this.formData.name || null,
                imageUrl: this.formData.imageUrl || null,
                breed: this.formData.breed || null,
                age: this.formData.age !== '' ? parseInt(this.formData.age) : null,
                uniqueFeatures: this.formData.uniqueFeatures || null,
                size: this.formData.size || null
            },
            report: {
                address: this.formData.address || null,
                disappearancePlaceLongitude: this.formData.disappearancePlaceLongitude !== '' ? parseFloat(this.formData.disappearancePlaceLongitude) : null,
                disappearancePlaceLatitude: this.formData.disappearancePlaceLatitude !== '' ? parseFloat(this.formData.disappearancePlaceLatitude) : null,
                disappearanceDate: this.formData.disappearanceDate || null,
                description: this.formData.description || null
            }
        };

        createMissingAnimalReport({ missingAnimalWrapper: missingAnimalWrapper })
        .then(result => {
            if (result === 'Success') {
                this.showToast('Success', 'Missing animal report created successfully', 'success');
                this.showForm = false;
                this.formData = {};
                this.loadAnimals();
            } else {
                this.handleSubmitError(result);
            }
        })
    }

    validateFormName() {
        if (this.formData.name.trim() === '') {
            this.showToast('Error', 'Animal name is required', 'error');
            return false;
        }
        return true;
    }

    handleSubmitError(result) {
        let message = 'Unknown error';
        
        switch(result) {
            case 'Null token':
                message = 'Authentication error';
                break;
            case 'Missing data':
                message = 'Missing required data';
                break;
            case 'Missing location':
                message = 'Please provide either an address or coordinates';
                break;
            case 'Missing date':
                message = 'Disappearance date is required';
                break;
            case 'Missing description':
                message = 'Description is required';
                break;
            case 'Exception error':
                message = 'Server error occurred';
                break;
            case 'Api error':
                message = 'API error';
                break;
            default:
                message = result;
        }
        
        this.showToast('Error', message, 'error');
    }

    handleMarkAsFound(event) {
        const animalId = event.target.dataset.id;
        this.updateFoundStatus(animalId, true);
    }

    updateFoundStatus(animalId, found) {
        updateAnimalFoundStatus({ animalId: animalId, found: found })
            .then(result => {
                if (result === 'Success') {
                    this.showToast('Success', 'Animal status updated to found', 'success');
                    this.loadAnimals();
                } else {
                    this.showToast('Error', `Failed to update status: ${result}`, 'error');
                }
            })
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
}