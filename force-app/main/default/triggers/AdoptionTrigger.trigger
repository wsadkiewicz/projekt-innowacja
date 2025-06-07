trigger AdoptionTrigger on Adoption__c (before insert, before update, before delete, after insert, after update, after delete) {
        new AdoptionTriggerHandler().run();
}