import { LightningElement, api, wire, track } from 'lwc';
import getOpeningHours from '@salesforce/apex/ShelterOpeningHoursController.getOpeningHours';

export default class ShelterOpeningHours extends LightningElement {
    @api recordId;
    @track displayHours = [];
    @track error;
    isLoading = true;

    dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    @wire(getOpeningHours, { shelterId: '$recordId' })
    wiredHours({ data, error }) {
        this.isLoading = true;

        if (data) {
            this.displayHours = data
                .map(hour => {
                    return {
                        ...hour,
                        displayOpen: this.formatTime(hour.Open__c, hour.Closed__c),
                        displayClose: this.formatTime(hour.Close__c, hour.Closed__c)
                    };
                })
                .sort((a, b) => {
                    const indexA = this.dayOrder.indexOf(a.Day__c);
                    const indexB = this.dayOrder.indexOf(b.Day__c);
                    return indexA - indexB;
                });

            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.displayHours = [];
            console.error('Error fetching opening hours:', error);
        }

        this.isLoading = false;
    }

 formatTime(timeValue, isClosed) {
    if (isClosed || timeValue == null) {
        return '';
    }

    try {
        const milliseconds = parseInt(timeValue, 10);
        const date = new Date(milliseconds);
        const hours = date.getUTCHours().toString().padStart(2, '0');
        const minutes = date.getUTCMinutes().toString().padStart(2, '0');
        return `${hours}:${minutes}`;
    } catch (e) {
        console.error('Error formatting time:', timeValue, e);
        return '';
    }
}

    get hasData() {
        return this.displayHours.length > 0;
    }

    get userFriendlyError() {
        if (this.error) {
            if (this.error.body && this.error.body.message) {
                return `Error: ${this.error.body.message}`;
            } else if (this.error.message) {
                return `Error: ${this.error.message}`;
            }
            return 'An error occurred while loading opening hours.';
        }
        return undefined;
    }

    get showNoDataMessage() {
        return !this.isLoading && !this.hasData && !this.userFriendlyError;
    }
}
