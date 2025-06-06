import { LightningElement, api, wire, track } from 'lwc';
import getOpeningHours from '@salesforce/apex/ShelterOpeningHoursController.getOpeningHours';
import saveOpeningHours from '@salesforce/apex/ShelterOpeningHoursController.saveOpeningHours';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


const DEFAULT_OPEN_TIME = '09:00';
const DEFAULT_CLOSE_TIME = '17:00';
const DAYS = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const BADGE_CLASSES = {
    OPEN: 'slds-badge slds-theme_success',
    CLOSED: 'slds-badge slds-theme_error'
};

export default class ShelterOpeningHours extends LightningElement {
    @api recordId;
    @track hours = [];
    isEditing = false;
    
    days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    connectedCallback() {
        this.initHours();
    }

    initHours() {
        this.hours = DAYS.map(day => this.createHourObject(day));
    }

    createHourObject(day, savedData = null) {
        if (savedData) {
            return {
                day,
                id: savedData.Id,
                open: savedData.Closed__c ? '' : this.formatTime(savedData.Open__c),
                close: savedData.Closed__c ? '' : this.formatTime(savedData.Close__c),
                closed: savedData.Closed__c,
                info: savedData.Additional_Info__c || '',
                displayTime: savedData.Closed__c ? 'Closed' : `${this.formatTime(savedData.Open__c)} - ${this.formatTime(savedData.Close__c)}`,
                status: savedData.Closed__c ? 'Closed' : 'Open',
                badgeClass: savedData.Closed__c ? BADGE_CLASSES.CLOSED : BADGE_CLASSES.OPEN
            };
        }
        
        return {
            day,
            open: DEFAULT_OPEN_TIME,
            close: DEFAULT_CLOSE_TIME,
            closed: false,
            info: '',
            displayTime: `${DEFAULT_OPEN_TIME} - ${DEFAULT_CLOSE_TIME}`,
            status: 'Open',
            badgeClass: BADGE_CLASSES.OPEN
        };
    }

    @wire(getOpeningHours, { shelterId: '$recordId' })
    wiredHours({ data }) {
        if (data) {
            const hourMap = new Map(data.map(h => [h.Day__c, h]));
            this.hours = DAYS.map(day => {
                const saved = hourMap.get(day);
                return saved ? this.createHourObject(day, saved) : this.createHourObject(day);
            });
        }
    }

    formatTime(ms) {
        if (!ms) return '';
        const d = new Date(ms);
        return `${String(d.getUTCHours()).padStart(2, '0')}:${String(d.getUTCMinutes()).padStart(2, '0')}`;
    }

    timeToMs(time) {
        if (!time) return null;
        const [h, m] = time.split(':').map(Number);
        return new Date(0).setUTCHours(h, m, 0, 0);
    }

    handleChange(e) {
        const { day, field } = e.target.dataset;
        const value = e.target.value;
        
        this.updateHourField(day, field, value);
    }

    updateHourField(day, field, value) {
        const hour = this.hours.find(h => h.day === day);
        if (hour) {
            hour[field] = value;
            this.updateDisplayProperties(hour);
        }
    }

    updateDisplayProperties(hour) {
        if (hour.closed) {
            hour.displayTime = 'Closed';
            hour.status = 'Closed';
            hour.badgeClass = BADGE_CLASSES.CLOSED;
        } else {
            hour.displayTime = `${hour.open} - ${hour.close}`;
            hour.status = 'Open';
            hour.badgeClass = BADGE_CLASSES.OPEN;
        }
    }

    toggleClosed(e) {
        const hour = this.hours.find(h => h.day === e.target.dataset.day);
        const isClosed = e.target.checked;
        
        this.setClosedStatus(hour, isClosed);
    }

    setClosedStatus(hour, isClosed) {
        hour.closed = isClosed;
        
        if (isClosed) {
            hour.open = '';
            hour.close = '';
        } else {
            hour.open = DEFAULT_OPEN_TIME;
            hour.close = DEFAULT_CLOSE_TIME;
        }
        
        this.updateDisplayProperties(hour);
    }

    toggleEdit() {
        if (this.isEditing) {
            this.saveData();
        } else {
            this.startEditing();
        }
    }

    startEditing() {
        this.isEditing = true;
    }

    async saveData() {
        try {
            const toSave = this.prepareDataForSave();
            await saveOpeningHours({ openingHoursList: toSave, shelterId: this.recordId });
            this.handleSaveSuccess();
        } catch (error) {
            this.handleSaveError(error);
        }
    }

    prepareDataForSave() {
        return this.hours.map(h => ({
            Id: h.id,
            Day__c: h.day,
            Open__c: h.closed ? null : this.timeToMs(h.open),  
            Close__c: h.closed ? null : this.timeToMs(h.close),
            Closed__c: h.closed,
            Shelter__c: this.recordId,
            Additional_Info__c: h.info
        }));
    }

    handleSaveSuccess() {
        this.showToast('Success', 'Saved!', 'success');
        this.isEditing = false;
    }

    handleSaveError(error) {
        this.showToast('Error', error.body?.message || 'Save failed', 'error');
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get editButtonLabel() {
        return this.isEditing ? 'Save' : 'Edit';
    }
}