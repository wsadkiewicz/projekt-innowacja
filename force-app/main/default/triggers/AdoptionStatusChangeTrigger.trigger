trigger AdoptionStatusChangeTrigger on Adoption__c (after update) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        AdoptionEmailManager.sendAdoptionStatusEmails(Trigger.new, Trigger.oldMap);
    }
}