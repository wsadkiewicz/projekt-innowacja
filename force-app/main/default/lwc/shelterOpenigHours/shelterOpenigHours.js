import { LightningElement, api, wire, track } from 'lwc';
import getOpeningHours from '@salesforce/apex/ShelterOpeningHoursController.getOpeningHours';
import saveOpeningHours from '@salesforce/apex/ShelterOpeningHoursController.saveOpeningHours';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class ShelterOpeningHours extends LightningElement {
    @api recordId;
    @track hours = [];
    isEditing = false;
    
    days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    connectedCallback() {
        this.initHours();
    }

    initHours() {
        this.hours = this.days.map(day => ({
            day,
            open: '09:00',
            close: '17:00',
            closed: false,
            info: '',
            get displayTime() {
                return this.closed ? 'Closed' : `${this.open} - ${this.close}`;
            },
            get status() {
                return this.closed ? 'Closed' : 'Open';
            },
            get badgeClass() {
                return `slds-badge ${this.closed ? 'slds-theme_error' : 'slds-theme_success'}`;
            }
        }));
    }

    @wire(getOpeningHours, { shelterId: '$recordId' })
    wiredHours({ data }) {
        if (data) {
            const hourMap = new Map(data.map(h => [h.Day__c, h]));
            this.hours = this.days.map(day => {
                const saved = hourMap.get(day);
                if (saved) {
                    return {
                        day,
                        id: saved.Id,
                        open: saved.Closed__c ? '' : this.formatTime(saved.Open__c),
                        close: saved.Closed__c ? '' : this.formatTime(saved.Close__c),
                        closed: saved.Closed__c,
                        info: saved.Additional_Info__c || '',
                        get displayTime() {
                            return this.closed ? 'Closed' : `${this.open} - ${this.close}`;
                        },
                        get status() {
                            return this.closed ? 'Closed' : 'Open';
                        },
                        get badgeClass() {
                            return `slds-badge ${this.closed ? 'slds-theme_error' : 'slds-theme_success'}`;
                        }
                    };
                }
                return {
                    day,
                    open: '09:00',
                    close: '17:00',
                    closed: false,
                    info: '',
                    get displayTime() {
                        return this.closed ? 'Closed' : `${this.open} - ${this.close}`;
                    },
                    get status() {
                        return this.closed ? 'Closed' : 'Open';
                    },
                    get badgeClass() {
                        return `slds-badge ${this.closed ? 'slds-theme_error' : 'slds-theme_success'}`;
                    }
                };
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
        const hour = this.hours.find(h => h.day === day);
        if (hour) {
            hour[field] = e.target.value;
        }
    }

    toggleClosed(e) {
        const hour = this.hours.find(h => h.day === e.target.dataset.day);
        hour.closed = e.target.checked;
        hour.open = hour.closed ? '' : '09:00';
        hour.close = hour.closed ? '' : '17:00';
    }

    toggleEdit() {
        if (this.isEditing) {
            this.saveData();
        } else {
            this.isEditing = true;
        }
    }

    async saveData() {
        try {
            const toSave = this.hours.map(h => ({
                Id: h.id,
                Day__c: h.day,
                Open__c: h.closed ? null : this.timeToMs(h.open),  
                Close__c: h.closed ? null : this.timeToMs(h.close), 
                Closed__c: h.closed,
                Shelter__c: this.recordId,
                Additional_Info__c: h.info
            }));
            
            await saveOpeningHours({ openingHoursList: toSave, shelterId: this.recordId });
            this.showToast('Success', 'Saved!', 'success');
            this.isEditing = false;
        } catch (error) {
            this.showToast('Error', error.body?.message || 'Save failed', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    get editButtonLabel() {
        return this.isEditing ? 'Save' : 'Edit';
    }
}