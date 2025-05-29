trigger AdoptionTrigger on Adoption__c (after insert, after update, after delete) {
    if(Trigger.isAfter){
        AdoptionTriggerHandler handler = new AdoptionTriggerHandler();

        if(Trigger.isInsert){
            handler.handleAfterInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            handler.handleAfterUpdate(Trigger.new);
        }
        if(Trigger.isDelete){
            handler.handleAfterDelete(Trigger.old);
        }
    }
}
