import { LightningElement, api, wire, track } from 'lwc';
import getOpeningHours from '@salesforce/apex/ShelterOpeningHoursController.getOpeningHours';
import saveOpeningHours from '@salesforce/apex/ShelterOpeningHoursController.saveOpeningHours';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ShelterOpeningHours extends LightningElement {
    @api recordId;
    @track displayHours = [];
    @track error;
    isLoading = true;
    isEditing = false;

    static DAYS_ORDER = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    static DEFAULT_TIMES = { open: '09:00', close: '17:00' };
    static TIME_REGEX = /^\d{2}:\d{2}$/;

    connectedCallback() {
        this.initializeDisplayHours();
    }

    initializeDisplayHours() {
        this.displayHours = ShelterOpeningHours.DAYS_ORDER.map(day => 
            this.createDayData(day, null, false)
        );
    }

    createDayData(day, existingHour = null, closed = false) {
        const { open: defaultOpen, close: defaultClose } = ShelterOpeningHours.DEFAULT_TIMES;
        
        if (existingHour) {
            return this.addDynamicProperties({
                ...existingHour,
                displayOpen: this.formatTime(existingHour.Open__c, existingHour.Closed__c),
                displayClose: this.formatTime(existingHour.Close__c, existingHour.Closed__c)
            });
        }

        return this.addDynamicProperties({
            Id: null,
            Day__c: day,
            Open__c: closed ? null : this.timeToMilliseconds(defaultOpen),
            Close__c: closed ? null : this.timeToMilliseconds(defaultClose),
            Closed__c: closed,
            Additional_Info__c: '',
            displayOpen: closed ? '' : defaultOpen,
            displayClose: closed ? '' : defaultClose
        });
    }

    addDynamicProperties(hourData) {
        return {
            ...hourData,
            get toggleLabel() { 
                return this.Closed__c ? 'Mark as Open' : 'Mark as Closed'; 
            },
            get statusBadgeText() { 
                return this.Closed__c ? 'Closed' : 'Open'; 
            },
            get statusBadgeClass() { 
                return `slds-badge ${this.Closed__c ? 'slds-theme_error' : 'slds-theme_success'}`; 
            }
        };
    }

    originalHoursData = null;

    @wire(getOpeningHours, { shelterId: '$recordId' })
    wiredHours({ data, error }) {
        if (data) {
            this.originalHoursData = data; 
            this.processHoursData(data);
            this.error = undefined;
        } else if (error) {
            this.handleError(error);
            this.initializeDisplayHours();
        }
        this.isLoading = false;
    }

    processHoursData(data) {
        const hoursMap = new Map(data.map(hour => [hour.Day__c, hour]));
        
        this.displayHours = ShelterOpeningHours.DAYS_ORDER.map(dayName => {
            const existingHour = hoursMap.get(dayName);
            return this.createDayData(dayName, existingHour);
        });
    }

    handleError(error) {
        this.error = error;
        console.error('Error fetching opening hours:', error);
    }

    formatTime(timeValue, isClosed) {
        if (isClosed || timeValue == null) return '';
                if (typeof timeValue === 'string' && ShelterOpeningHours.TIME_REGEX.test(timeValue)) {
            return timeValue;
        }

        try {
            const milliseconds = parseInt(timeValue, 10);
            if (isNaN(milliseconds)) return '';
            
            const date = new Date(milliseconds);
            return `${date.getUTCHours().toString().padStart(2, '0')}:${date.getUTCMinutes().toString().padStart(2, '0')}`;
        } catch (e) {
            console.error('Error formatting time:', timeValue, e);
            return '';
        }
    }

    timeToMilliseconds(timeString) {
        if (!timeString) return null;
        
        try {
            const [hours, minutes] = timeString.split(':').map(Number);
            if (isNaN(hours) || isNaN(minutes)) return null;
            
            const date = new Date(0);
            date.setUTCHours(hours, minutes, 0, 0);
            return date.getTime();
        } catch (e) {
            console.error('Error converting time to milliseconds:', timeString, e);
            return null;
        }
    }

    findHourEntry(day) {
        return this.displayHours.find(h => h.Day__c === day);
    }

    handleTimeChange(event) {
        const { day, field } = event.target.dataset;
        const value = event.target.value;
        
        const hourEntry = this.findHourEntry(day);
        if (!hourEntry) return;

        const displayFieldKey = field === 'Open__c' ? 'displayOpen' : 'displayClose';
        hourEntry[displayFieldKey] = value;
        
        hourEntry[field] = this.timeToMilliseconds(value);
    }

    handleToggleClosed(event) {
        const day = event.target.dataset.day;
        const hourEntry = this.findHourEntry(day);
        if (!hourEntry) return;

        hourEntry.Closed__c = !hourEntry.Closed__c;
        
        if (hourEntry.Closed__c) {
            this.setClosedState(hourEntry);
        } else {
            this.setOpenState(hourEntry);
        }
    }

    setClosedState(hourEntry) {
        hourEntry.displayOpen = '';
        hourEntry.displayClose = '';
        hourEntry.Open__c = null;
        hourEntry.Close__c = null;
    }

    setOpenState(hourEntry) {
        const { open: defaultOpen, close: defaultClose } = ShelterOpeningHours.DEFAULT_TIMES;
        hourEntry.displayOpen = defaultOpen;
        hourEntry.displayClose = defaultClose;
        hourEntry.Open__c = this.timeToMilliseconds(defaultOpen);
        hourEntry.Close__c = this.timeToMilliseconds(defaultClose);
    }

    handleAdditionalInfoChange(event) {
        const day = event.target.dataset.day;
        const hourEntry = this.findHourEntry(day);
        if (hourEntry) {
            hourEntry.Additional_Info__c = event.target.value;
        }
    }

    handleEdit() {
        this.isEditing = true;
    }

    handleCancel() {
        this.isEditing = false;
        if (this.originalHoursData) {
            this.processHoursData(this.originalHoursData);
        } else {
            this.initializeDisplayHours();
        }
        this.isLoading = false;
        this.error = undefined;
    }

    async handleSave() {
        this.isLoading = true;

        try {
            const hoursToSave = this.prepareDataForSave();
            await saveOpeningHours({ 
                openingHoursList: hoursToSave, 
                shelterId: this.recordId 
            });
            
            this.showToast('Success', 'Opening hours saved successfully.', 'success');
            this.isEditing = false;

            this.originalHoursData = hoursToSave;
            this.processHoursData(hoursToSave);
        } catch (error) {
            this.showToast(
                'Error saving opening hours',
                error.body?.message || error.message,
                'error'
            );
            this.error = error;
        } finally {
            this.isLoading = false;
        }
    }

    prepareDataForSave() {
        return this.displayHours.map(hour => {
            const baseData = {
                Day__c: hour.Day__c,
                Open__c: hour.Closed__c ? null : hour.Open__c,
                Close__c: hour.Closed__c ? null : hour.Close__c,
                Closed__c: hour.Closed__c,
                Additional_Info__c: hour.Additional_Info__c
            };

            if (hour.Id) {
                baseData.Id = hour.Id;
            } else {
                baseData.Shelter__c = this.recordId;
            }
            
            return baseData;
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get hasData() {
        return this.displayHours?.length > 0;
    }
}