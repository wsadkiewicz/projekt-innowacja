trigger AnimalTrigger on Animal__c (after insert) {
    if(Trigger.isAfter){
        AnimalTriggerHandler handler = new AnimalTriggerHandler();

        if(Trigger.isInsert){
            handler.handleAfterInsert(Trigger.new);
        }
    }
}